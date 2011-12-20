// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 15/12/2011
//
//  Copyright 2011 Sam Deane, Elegant Chaos. All rights reserved.
//  This source code is distributed under the terms of Elegant Chaos's 
//  liberal license: http://www.elegantchaos.com/license/liberal
// --------------------------------------------------------------------------

#import <ServiceManagement/ServiceManagement.h>
#import <Security/Authorization.h>

#import "HostAppController.h"
#import "Injector.h"
#import "Injected.h"

@interface HostAppController()

#pragma mark - Private Properties

@property (nonatomic, retain) NSConnection* injectedConnection;
@property (nonatomic, retain) NSString* injectedID;
@property (nonatomic, retain) NSConnection* injectorConnection;
@property (nonatomic, retain) NSString* injectorID;

#pragma mark - Private Methods

- (Injector*)injector;
- (Injected*)injected;
- (OSStatus)setupAuthorization:(AuthorizationRef*)authRef;
- (NSError*)installInjectorApplication;
- (void)setStatus:(NSString*)status error:(NSError*)error;
- (void)updateUI;

@end

#pragma mark -

@implementation HostAppController

#pragma mark - Properties

@synthesize injectedConnection;
@synthesize injectedID;
@synthesize injectorConnection;
@synthesize injectorID;
@synthesize label;
@synthesize targetBundleID;

#pragma mark - Object Lifecycle

// --------------------------------------------------------------------------
//! Cleanup.
// --------------------------------------------------------------------------

- (void)dealloc 
{
    [injectedConnection release];
    [injectedID release];
    [injectorConnection release];
    [injectorID release];
    [targetBundleID release];
    
    [super dealloc];
}

#pragma mark - NSApplicationDelegate

// --------------------------------------------------------------------------
//! Finish setting up after launch.
// --------------------------------------------------------------------------

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    // look up the injector bundle id in our plist
    // (we're assuming that it's the one and only key inside the SMPrivilegedExecutables dictionary)
    NSDictionary* helpers = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"SMPrivilegedExecutables"];
    self.injectorID = [[helpers allKeys] objectAtIndex:0];
    
    // look up the injected bundle id
    NSURL* bundleURL = [[NSBundle mainBundle] URLForResource:@"injected" withExtension:@"bundle" subdirectory:@"Injection"];
    self.injectedID = [[NSBundle bundleWithURL:bundleURL] bundleIdentifier];

    self.targetBundleID = @"com.apple.finder";
    [self updateUI];
}

#pragma mark - Utilities

- (void)updateUI
{
    Injected* injected = [self injected];
    Injector* injector = [self injector];
    
    NSString* injectedStatus = injected ? @"Injected code running." : @"Injected code not found";
    NSString* injectorStatus = injector ? @"Injector is running." : @"Injector not found";
    
    [self setStatus:[NSString stringWithFormat:@"%@\n%@", injectedStatus, injectorStatus] error:nil];
}

// --------------------------------------------------------------------------
//! Update the UI with some status info.
// --------------------------------------------------------------------------

- (void)setStatus:(NSString*)status error:(NSError*)error;
{
    NSLog(@"%@", status);
    [self.label setStringValue:status];
    if (error)
    {
        NSLog(@"Error: %@", error);
        [[NSApplication sharedApplication] presentError:error];
    }
}

#pragma mark - Installation

// --------------------------------------------------------------------------
//! Prepare to authorize.
// --------------------------------------------------------------------------

- (OSStatus)setupAuthorization:(AuthorizationRef*)authRef
{
	AuthorizationItem authItem		= { kSMRightBlessPrivilegedHelper, 0, NULL, 0 };
	AuthorizationRights authRights	= { 1, &authItem };
	AuthorizationFlags flags		=	kAuthorizationFlagDefaults				| 
    kAuthorizationFlagInteractionAllowed	|
    kAuthorizationFlagPreAuthorize			|
    kAuthorizationFlagExtendRights;
    
	
	// Obtain the right to install privileged helper tools (kSMRightBlessPrivilegedHelper).
	OSStatus status = AuthorizationCreate(&authRights, kAuthorizationEmptyEnvironment, flags, authRef);
	if (status != errAuthorizationSuccess) 
    {
        *authRef = nil;
	}
    
    return status;
}

// --------------------------------------------------------------------------
//! Attempt to install the injector.
// --------------------------------------------------------------------------

- (NSError*)installInjectorApplication
{
	// Obtain the right to install privileged helper tools (kSMRightBlessPrivilegedHelper).
    NSError* error = nil;
	AuthorizationRef authRef;
    OSStatus status = [self setupAuthorization:&authRef];
	if (status == errAuthorizationSuccess) 
    {
		/* This does all the work of verifying the helper tool against the application
		 * and vice-versa. Once verification has passed, the embedded launchd.plist
		 * is extracted and placed in /Library/LaunchDaemons and then loaded. The
		 * executable is placed in /Library/PrivilegedHelperTools.
		 */
		SMJobBless(kSMDomainSystemLaunchd, (CFStringRef) self.injectorID, authRef, (CFErrorRef*) error);
    }
    else
    {
        error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:[NSDictionary dictionaryWithObject:@"failed to get authorisation" forKey:NSLocalizedFailureReasonErrorKey]];
	} 

    
	return error;
}

#pragma mark - Injector

// --------------------------------------------------------------------------
//! Return a proxy to the helper object in the helper tool.
//! Sets up the connection when it's first called.
//! Returns nil if it can't connect for any reason
//! (eg the helper isn't installed or isn't running)
// --------------------------------------------------------------------------

- (Injector*)injector
{
    Injector* injector = nil;
    
    @try 
    {
        if (!self.injectorConnection)
        {
            // Lookup the server connection
            self.injectorConnection = [NSConnection connectionWithRegisteredName:self.injectorID host:nil];
            if (!self.injectorConnection)
            {
                NSLog(@"%@ server: could not find server.  You need to start one on this machine first.\n", self.injectorID);
            }
            else
            {
                [self.injectorConnection setRequestTimeout:10.0];
                [self.injectorConnection setReplyTimeout:10.0];
            }
        }
        
        if (self.injectorConnection)
        {
            NSDistantObject *proxy = [self.injectorConnection rootProxy];
            if (!proxy) 
            {
                NSLog(@"could not get proxy");
            }
            
            injector = (Injector*)proxy;
        }
    }
    @catch (NSException *exception) 
    {
        NSLog(@"exception thrown whilst trying to connect to injector: %@", exception);
    }

    return injector;
}

// --------------------------------------------------------------------------
//! Return a proxy to the injected code.
//! Sets up the connection when it's first called.
//! Returns nil if it can't connect for any reason
//! (eg the code isn't injected)
// --------------------------------------------------------------------------

- (Injected*)injected
{
    Injected* injected = nil;
    
    @try
    {
        if (!self.injectedConnection)
        {
            // Lookup the server connection
            self.injectedConnection = [NSConnection connectionWithRegisteredName:self.injectedID host:nil];
            if (!self.injectedConnection)
            {
                NSLog(@"%@ server: could not find server.  You need to start one on this machine first.\n", self.injectedID);
            }
            else
            {
                [self.injectedConnection setRequestTimeout:10.0];
                [self.injectedConnection setReplyTimeout:10.0];
            }
        }
        
        if (self.injectedConnection)
        {
            NSDistantObject *proxy = [self.injectedConnection rootProxy];
            if (!proxy) 
            {
                NSLog(@"could not get proxy");
            }
            
            injected = (Injected*)proxy;
        }
    }
    @catch (NSException *exception) 
    {
        NSLog(@"exception thrown whilst trying to connect to injected: %@", exception);
    }

    return injected;
}

// --------------------------------------------------------------------------
//! Install the injector.
// --------------------------------------------------------------------------

- (IBAction)install:(id)sender
{
    // try to install ("bless") the helper tool
    // this will copy it into the right place and set up the launchd plist (if it isn't already there)
    NSError* error = [self installInjectorApplication];
	if (!error)
    {
        // it worked - try to communicate with it
        [self updateUI];
	}
    else
    {
        // it didn't work
        [self setStatus:@"Injector could not be installed" error:error];
	} 

}

// --------------------------------------------------------------------------
//! Send a "command" to the injector.
//! In this example a command is just a string that we send
//! by invoking the doCommand method on the injector.
// --------------------------------------------------------------------------

- (IBAction)inject:(id)sender
{
    Injector* injector = [self injector];
    NSString* bundlePath = [[NSBundle mainBundle] pathForResource:@"injected" ofType:@"bundle" inDirectory:@"Injection"];
    OSStatus result = [injector injectBundleAtPath:bundlePath intoApplicationWithId:targetBundleID];
    if (result == noErr)
    {
        NSLog(@"injected ok");
    }
    else
    {
        NSLog(@"injection failed with error %d", result);
    }
}

@end

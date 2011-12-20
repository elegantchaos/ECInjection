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

@interface HostAppController()

#pragma mark - Private Properties

@property (nonatomic, retain) NSConnection* connection;
@property (nonatomic, retain) NSString* injectorID;

#pragma mark - Private Methods

- (Injector*)injector;
- (OSStatus)setupAuthorization:(AuthorizationRef*)authRef;
- (NSError*)installInjectorApplication;
- (void)setStatus:(NSString*)status error:(NSError*)error;

@end

#pragma mark -

@implementation HostAppController

#pragma mark - Properties

@synthesize connection;
@synthesize injectorID;
@synthesize label;

#pragma mark - Object Lifecycle

// --------------------------------------------------------------------------
//! Cleanup.
// --------------------------------------------------------------------------

- (void)dealloc 
{
    [connection release];
    [injectorID release];
    
    [super dealloc];
}

#pragma mark - NSApplicationDelegate

// --------------------------------------------------------------------------
//! Finish setting up after launch.
// --------------------------------------------------------------------------

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    // try to install ("bless") the helper tool
    // this will copy it into the right place and set up the launchd plist (if it isn't already there)
    NSError* error = [self installInjectorApplication];
	if (!error)
    {
        // it worked - try to communicate with it
		[self setStatus:@"Injector is available" error:error];
        Injector* injector = [self injector];
        if (injector)
        {
            // we got a connection to it
            [self setStatus:[NSString stringWithFormat:@"Injector is running"] error:error];
        }
        else
        {
            // failed to get a connection, that might just be because it's not started
            [self setStatus:@"Injector is installed, but not running" error:error];
        }
	}
    else
    {
        // it didn't work
        [self setStatus:@"Injector could not be installed" error:error];
	} 
}

// --------------------------------------------------------------------------
//! Cleanup before shutdown.
// --------------------------------------------------------------------------

- (void)applicationWillTerminate:(NSNotification *)notification
{
    self.connection = nil;
}

#pragma mark - Utilities

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
    // look up the injector bundle id in our plist
    // (we're assuming that it's the one and only key inside the SMPrivilegedExecutables dictionary)
    NSDictionary* helpers = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"SMPrivilegedExecutables"];
    self.injectorID = [[helpers allKeys] objectAtIndex:0];

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
    
    if (!self.connection)
    {
        // Lookup the server connection
        NSString* name = @"com.elegantchaos.injection.injector";
        self.connection = [NSConnection connectionWithRegisteredName:name host:nil];
        if (!self.connection)
        {
            NSLog(@"%@ server: could not find server.  You need to start one on this machine first.\n", name);
        }
        else
        {
            [self.connection setRequestTimeout:10.0];
            [self.connection setReplyTimeout:10.0];
        }
    }

    if (self.connection)
    {
        NSDistantObject *proxy = [self.connection rootProxy];
        if (!proxy) 
        {
            NSLog(@"could not get proxy");
        }
        
        injector = (Injector*)proxy;
    }

    return injector;
}

// --------------------------------------------------------------------------
//! Send a "command" to the injector.
//! In this example a command is just a string that we send
//! by invoking the doCommand method on the injector.
// --------------------------------------------------------------------------

- (IBAction)inject:(id)sender
{
    Injector* injector = [self injector];
    NSURL* bundleURL = [[NSBundle mainBundle] URLForResource:@"injected" withExtension:@"bundle" subdirectory:@"Injection"];
    
    OSStatus result = [injector injectBundleAtURL:bundleURL intoApplicationWithId:@"com.apple.finder"];
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

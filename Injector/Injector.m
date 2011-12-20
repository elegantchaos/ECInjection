// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 15/12/2011
//
//  Copyright 2011 Sam Deane, Elegant Chaos. All rights reserved.
//  This source code is distributed under the terms of Elegant Chaos's 
//  liberal license: http://www.elegantchaos.com/license/liberal
// --------------------------------------------------------------------------

#import "Injector.h"

#import "ECASLClient.h"

#include <CoreServices/CoreServices.h>
#include <Foundation/Foundation.h>
//#include <AppKit/AppKit.h>
#include <AppKit/NSRunningApplication.h>

#include "mach_inject.h"
#include "mach_inject_bundle_stub.h"
#include <CoreServices/CoreServices.h>



@interface Injector()

#pragma mark - Private Properties

@property (nonatomic, retain) ECASLClient *asl;

@end

@implementation Injector

#pragma mark - Properties

@synthesize asl;

#pragma mark - Object Lifecycle

// --------------------------------------------------------------------------
//! Set up.
// --------------------------------------------------------------------------

- (id)initWithASL:(ECASLClient *)aslIn
{
    if ((self = [super init]) != nil)
    {
        self.asl = aslIn;
        [aslIn log:@"injector initialised"];
    }
    
    return self;
}

// --------------------------------------------------------------------------
//! Cleanup.
// --------------------------------------------------------------------------

- (void)dealloc 
{
    [asl release];
    
    [super dealloc];
}

#pragma mark - Injection

// --------------------------------------------------------------------------
//! Return the process id for the running application with a given bundle id.
//! Returns zero if the process isn't found.
// --------------------------------------------------------------------------

- (pid_t)processWithId:(NSString*)appId
{
    pid_t result = 0;
    NSArray* apps = [[NSWorkspace sharedWorkspace] runningApplications];
    for (NSRunningApplication* app in apps)
    {
        if ([[app bundleIdentifier] isEqualToString:appId])
        {
            result = [app processIdentifier];
            break;
        }
    }
    
    return result;
}

// --------------------------------------------------------------------------
//! Inject the bundle at a given path into the application with a given id.
//! We expect to find the mach_inject_bundle_stub bundle inside
//! the bundle that we're going to inject.
// --------------------------------------------------------------------------

- (OSStatus)injectBundleAtPath:(NSString*)bundlePath intoApplicationWithId:(NSString*)appId
{
    OSStatus result = noErr;
    pid_t process_id = [self processWithId:appId];
    if (process_id)
    {
        // get the injection stub bundle
        NSURL* injectionURL = [NSURL fileURLWithPath:[bundlePath stringByAppendingPathComponent:@"Contents/Resources/Injection/mach_inject_bundle_stub.bundle"]];
        CFBundleRef injectionBundle = CFBundleCreate( kCFAllocatorDefault, (CFURLRef) injectionURL);
        if( !injectionBundle )
        {
            [self.asl error:@"failed to load injection bundle"];
            result = kErrorCouldntLoadInjectionBundle;
        }

        // get the function pointer for the stub entrypoint 
        void* injectionCode = CFBundleGetFunctionPointerForName((CFBundleRef) injectionBundle, CFSTR( INJECT_ENTRY_SYMBOL ));
        if( injectionCode == NULL )
        {
            [self.asl error:@"failed to find injection entry symbol"];
            result = kErrorCouldntFindInjectEntrySymbol;
        }

        // inject the code
        mach_inject_bundle_stub_param *param = NULL;
        size_t paramSize;
        if( !result )
        {
            const char* bundle_c = [bundlePath fileSystemRepresentation];
            size_t bundlePathSize = strlen(bundle_c) + 1;
            paramSize = sizeof( ptrdiff_t ) + bundlePathSize;
            param = malloc( paramSize );
            bcopy( bundle_c, param->bundlePackageFileSystemRepresentation, bundlePathSize );
            result = mach_inject( injectionCode, param, paramSize, process_id, 0 );
            free( param );
            if (result != err_none)
            {
                [self.asl error:@"injection failed with error %d", result];
            }
        }
    }
    else
    {
        result = kErrorCouldntFindProcess;
        [self.asl error:@"couldn't find process with id %@", appId];
    }
    
    return result;
}

@end


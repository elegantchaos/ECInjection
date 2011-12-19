// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 15/12/2011
//
//  Copyright 2011 Sam Deane, Elegant Chaos. All rights reserved.
//  This source code is distributed under the terms of Elegant Chaos's 
//  liberal license: http://www.elegantchaos.com/license/liberal
// --------------------------------------------------------------------------

#import "Injector.h"

#import <asl.h>

#include <CoreServices/CoreServices.h>
#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include <AppKit/NSRunningApplication.h>

#import <mach_inject_bundle/mach_inject_bundle.h>

@interface Injector()
@property (nonatomic, assign) aslclient aslClient;
@property (nonatomic, assign) aslmsg aslMsg;
@end

@implementation Injector

@synthesize aslClient;
@synthesize aslMsg;

- (id)initWithName:(NSString *)name
{
    if ((self = [super init]) != nil)
    {
        
       const char* name_c = [name UTF8String];
       self.aslClient = asl_open(name_c, "Injector", ASL_OPT_STDERR);
        self.aslMsg = asl_new(ASL_TYPE_MSG);
        asl_log(self.aslClient, aslMsg, ASL_LEVEL_NOTICE, "injector initialised");
    }
    
    return self;
}

- (void)dealloc 
{
    asl_free(self.aslMsg);
    asl_close(self.aslClient);
    
    [super dealloc];
}

- (void)log:(NSString *)msg
{
    asl_log(self.aslClient, self.aslMsg, ASL_LEVEL_NOTICE, "%s", [msg UTF8String]);
}

- (void)error:(NSString *)msg
{
    asl_log(self.aslClient, self.aslMsg, ASL_LEVEL_ERR, "%s", [msg UTF8String]);
}

- (OSStatus)injectBundleAtURL:(NSURL *)bundleURL intoApplicationWithId:(NSString *)appId
{
    const char* bundlePath = [[bundleURL path] fileSystemRepresentation];
	asl_log(aslClient, aslMsg, ASL_LEVEL_NOTICE, "injecting bundle %s into app %s", bundlePath, [appId UTF8String]);

    OSStatus result = fnfErr;
    NSArray* apps = [[NSWorkspace sharedWorkspace] runningApplications];
    for (NSRunningApplication* app in apps)
    {
        if ([[app bundleIdentifier] isEqualToString:appId])
        {
            pid_t process_id = [app processIdentifier];
            asl_log(aslClient, aslMsg, ASL_LEVEL_NOTICE, "injecting bundle %s into %s (%d)", bundlePath, [[app localizedName] UTF8String], process_id);
            result = mach_inject_bundle_pid(bundlePath, process_id);
            if (result != err_none)
            {
                asl_log(aslClient, aslMsg, ASL_LEVEL_ERR, "injection failed with error %d", result);
            }
            break;
        }
    }
    
    return result;
}

@end


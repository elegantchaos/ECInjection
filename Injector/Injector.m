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

#include "mach_inject.h"
#include "mach_inject_bundle_stub.h"
#include <CoreServices/CoreServices.h>

#define	err_mach_inject_bundle_couldnt_load_framework_bundle	(err_local|1)
#define	err_mach_inject_bundle_couldnt_find_injection_bundle	(err_local|2)
#define	err_mach_inject_bundle_couldnt_load_injection_bundle	(err_local|3)
#define	err_mach_inject_bundle_couldnt_find_inject_entry_symbol	(err_local|4)

#if 0
mach_error_t
mach_inject_bundle_pid(
                       const char	*bundlePackageFileSystemRepresentation,
                       pid_t		pid )
{
	assert( bundlePackageFileSystemRepresentation );
	assert( pid > 0 );
	
	mach_error_t	err = err_none;
	
	//	Find the injection bundle by name.
	CFURLRef injectionURL = NULL;
	if( !err ) {
		/*injectionURL = CFURLCreateWithFileSystemPath( kCFAllocatorDefault, CFSTR("mach_inject_bundle_stub.bundle"),
         kCFURLPOSIXPathStyle, true );*/
		injectionURL = CFBundleCopyResourceURL( frameworkBundle,
                                               CFSTR("mach_inject_bundle_stub.bundle"), NULL, NULL );
		
		/*char url[1024];
         CFURLGetFileSystemRepresentation(injectionURL, true, url, 1024);
         printf("got a URL %s\n", url);*/
		if( !injectionURL )
			err = err_mach_inject_bundle_couldnt_find_injection_bundle;
	}
	
	//	Create injection bundle instance.
	CFBundleRef injectionBundle = NULL;
	if( !err ) {
		injectionBundle = CFBundleCreate( kCFAllocatorDefault, injectionURL );
		if( !injectionBundle )
			err = err_mach_inject_bundle_couldnt_load_injection_bundle;
	}
	
	//	Load the thread code injection.
	void *injectionCode = NULL;
	if( !err ) {
		injectionCode = CFBundleGetFunctionPointerForName( injectionBundle,
                                                          CFSTR( INJECT_ENTRY_SYMBOL ));
		if( injectionCode == NULL )
			err = err_mach_inject_bundle_couldnt_find_inject_entry_symbol;
	}
	
	//	Allocate and populate the parameter block.
	mach_inject_bundle_stub_param *param = NULL;
	size_t paramSize;
	if( !err ) {
		size_t bundlePathSize = strlen( bundlePackageFileSystemRepresentation )
        + 1;
		paramSize = sizeof( ptrdiff_t ) + bundlePathSize;
		param = malloc( paramSize );
		bcopy( bundlePackageFileSystemRepresentation,
              param->bundlePackageFileSystemRepresentation,
              bundlePathSize );
	}
	
	//	Inject the code.
	if( !err ) {
		err = mach_inject( injectionCode, param, paramSize, pid, 0 );
	}
	
	//	Clean up.
	if( param )
		free( param );
	/*if( injectionBundle )
     CFRelease( injectionBundle );*/
	if( injectionURL )
		CFRelease( injectionURL );
	
	return err;
}
#endif

@interface Injector()
@property (nonatomic, assign) aslclient aslClient;
@property (nonatomic, assign) aslmsg aslMsg;
@property (nonatomic, retain) NSString* tempAppId;
@property (nonatomic, retain) NSURL* tempBundleURL;
@end

@implementation Injector

@synthesize aslClient;
@synthesize aslMsg;
@synthesize tempAppId;
@synthesize tempBundleURL;

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

- (pid_t)processWithId:(NSString*)appId
{
    pid_t result = 0;
    NSArray* apps = [[NSWorkspace sharedWorkspace] runningApplications];
    for (NSRunningApplication* app in apps)
    {
        if ([[app bundleIdentifier] isEqualToString:appId])
        {
            result = [app processIdentifier];
            asl_log(aslClient, aslMsg, ASL_LEVEL_NOTICE, "found app %s (%d)", [[app localizedName] UTF8String], result);
            break;
        }
    }
    
    return result;
}

- (OSStatus)injectBundleAtURL:(NSURL *)bundleURLIn intoApplicationWithId:(NSString *)appIdIn
{
    NSString* appId = [NSString stringWithString:appId];
    NSURL* bundleURL = [NSURL fileURLWithPath: [bundleURL path]];
    OSStatus result = noErr;
    pid_t process_id = [self processWithId:appId];
    if (process_id)
    {
        NSURL* container = [bundleURL URLByDeletingLastPathComponent];
        NSURL* injectionURL = [container URLByAppendingPathComponent:@"mach_inject_bundle_stub.bundle"];
        asl_log(aslClient, aslMsg, ASL_LEVEL_NOTICE, "injection bundle path is %s", [[injectionURL path] fileSystemRepresentation]);
        
        const char* bundlePath = [[bundleURL path] fileSystemRepresentation];
        asl_log(aslClient, aslMsg, ASL_LEVEL_NOTICE, "bundle path is %s", bundlePath);
        
        asl_log(aslClient, aslMsg, ASL_LEVEL_NOTICE, "CFBundleCreate is %ld", (long) CFBundleCreate);
        
        CFBundleRef injectionBundle = CFBundleCreate( kCFAllocatorDefault, (CFURLRef) injectionURL);

        asl_log(aslClient, aslMsg, ASL_LEVEL_NOTICE, "CFBundleCreate done");

        if( !injectionBundle )
        {
            asl_log(aslClient, aslMsg, ASL_LEVEL_ERR, "failed to load injection bundle");
            result = err_mach_inject_bundle_couldnt_load_injection_bundle;
        }

        if (injectionBundle)
        {
            asl_log(aslClient, aslMsg, ASL_LEVEL_NOTICE, "loaded stub bundle");
        }

        
        //	Load the thread code injection.
        asl_log(aslClient, aslMsg, ASL_LEVEL_NOTICE, "loading injection code");
        void* injectionCode = CFBundleGetFunctionPointerForName((CFBundleRef) injectionBundle, CFSTR( INJECT_ENTRY_SYMBOL ));
        if( injectionCode == NULL )
        {
            result = err_mach_inject_bundle_couldnt_find_inject_entry_symbol;
        }

        //	Allocate and populate the parameter block.
        mach_inject_bundle_stub_param *param = NULL;
        size_t paramSize;
        if( !result )
        {
            asl_log(aslClient, aslMsg, ASL_LEVEL_NOTICE, "populating parameter block");
            size_t bundlePathSize = strlen(bundlePath) + 1;
            paramSize = sizeof( ptrdiff_t ) + bundlePathSize;
            param = malloc( paramSize );
            bcopy( bundlePath, param->bundlePackageFileSystemRepresentation, bundlePathSize );
        }
        
        //	Inject the code.
        if( !result ) 
        {
            asl_log(aslClient, aslMsg, ASL_LEVEL_NOTICE, "injecting");
            result = mach_inject( injectionCode, param, paramSize, process_id, 0 );
        }
        
        //	Clean up.
        if( param )
            free( param );

        if (result != err_none)
        {
            asl_log(aslClient, aslMsg, ASL_LEVEL_ERR, "injection failed with error %d", result);
        }
    }
    
    return result;
}

@end


// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 15/12/2011
//
//  Copyright 2011 Sam Deane, Elegant Chaos. All rights reserved.
//  This source code is distributed under the terms of Elegant Chaos's 
//  liberal license: http://www.elegantchaos.com/license/liberal
// --------------------------------------------------------------------------

#import <Foundation/Foundation.h>
#import <mach/error.h>

#pragma mark - Injection Errors

enum
{
    kErrorCouldntFindProcess                = (err_local + 1),
    kErrorCouldntLoadInjectionBundle,
    kErrorCouldntFindInjectEntrySymbol
};

@class ECASLClient;

@interface Injector : NSObject

- (id)initWithASL:(ECASLClient*)asl;
- (OSStatus)injectBundleAtPath:(NSString*)bundlePath intoApplicationWithId:(NSString*)appId;
- (pid_t)processID;

@end

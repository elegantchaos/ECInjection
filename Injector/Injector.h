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
    kErrorCouldntFindInjectionBundle	= (err_local + 1),
    kErrorCouldntLoadInjectionBundle,
    kErrorCouldntFindInjectEntrySymbol
};

@interface Injector : NSObject

- (id)initWithName:(NSString*)name;
- (void)log:(NSString*)msg;
- (void)error:(NSString*)msg;
- (OSStatus)injectBundleAtPath:(NSString*)bundlePath intoApplicationWithId:(NSString*)appId;

@end

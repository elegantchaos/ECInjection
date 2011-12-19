// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 15/12/2011
//
//  Copyright 2011 Sam Deane, Elegant Chaos. All rights reserved.
//  This source code is distributed under the terms of Elegant Chaos's 
//  liberal license: http://www.elegantchaos.com/license/liberal
// --------------------------------------------------------------------------

#import <Foundation/Foundation.h>

@interface Injector : NSObject

- (id)initWithName:(NSString*)name;
- (void)log:(NSString*)msg;
- (void)error:(NSString*)msg;
- (OSStatus)injectBundleAtURL:(NSURL*)bundleURL intoApplicationWithId:(NSString*)appId;

@end

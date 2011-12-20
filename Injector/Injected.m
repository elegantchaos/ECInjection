// --------------------------------------------------------------------------
//! @author Sam Deane
//! @date 19/12/2011
//
//  Copyright 2011 Sam Deane, Elegant Chaos. All rights reserved.
//  This source code is distributed under the terms of Elegant Chaos's 
//  liberal license: http://www.elegantchaos.com/license/liberal
// --------------------------------------------------------------------------

#import "Injected.h"
#import <AppKit/AppKit.h>

@interface Injected()

#pragma mark - Private Methods

- (void)installMenu;
- (IBAction)testAction:(id)sender;
- (void)startListening;

@end

@implementation Injected

#pragma mark - Globals

static const Injected* gInjectedCode = nil;

#pragma mark - Loading

// --------------------------------------------------------------------------
//! Load the bundle and create our instance.
// --------------------------------------------------------------------------

+ (void)load 
{
    NSLog(@"injected code loaded");
    gInjectedCode = [[Injected alloc] init];
    
}

#pragma mark - Object Lifecycle

// --------------------------------------------------------------------------
//! Initialise.
// --------------------------------------------------------------------------

- (id)init 
{
    if ((self = [super init]) != nil) 
    {
        [self installMenu];
        [self startListening];
    }
    
    return self;
}

#pragma mark - Communications

// --------------------------------------------------------------------------
//! Make an NSConnection and start listening for commands.
// --------------------------------------------------------------------------

- (void)startListening
{
    // set up the connection
    NSMachPort* receivePort = [[NSMachPort alloc] init];
    NSConnection* server = [NSConnection connectionWithReceivePort:receivePort sendPort:nil];
    NSString* name = [[NSBundle bundleForClass:[self class]] bundleIdentifier];
    [server registerName:name];
    [receivePort release];
    [server setRootObject:self];
}

#pragma mark - Menus

// --------------------------------------------------------------------------
//! Install our menu at the end of the application's menubar.
// --------------------------------------------------------------------------

- (void)installMenu
{
    NSLog(@"adding Injector menu");
    NSMenu* menu = [[NSApplication sharedApplication] mainMenu];
    NSInteger index = [menu indexOfItemWithTitle:@"Injector"];
    if (index == -1)
    {
        NSMenuItem* injectorItem = [menu addItemWithTitle:@"Injector" action:nil keyEquivalent:@""];
        NSMenu* injectorMenu = [[NSMenu alloc] initWithTitle:@"Injector"];
        NSMenuItem* testItem = [injectorMenu addItemWithTitle:@"Test" action:@selector(testAction:) keyEquivalent:@""];
        testItem.target = self;
        
        [injectorItem setSubmenu:injectorMenu];
        [injectorMenu release];
    }
}

// --------------------------------------------------------------------------
//! Handle the "Test" menu item being chosen.
// --------------------------------------------------------------------------

- (IBAction)testAction:(id)sender
{
    NSLog(@"test action fired");
}

@end

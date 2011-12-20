#import "Injected.h"
#import <AppKit/AppKit.h>

@interface Injected()

- (void)installMenu;
- (IBAction)testAction:(id)sender;

@end

@implementation Injected

static const Injected* gInjectedCode = nil;

+ (void)load 
{
    NSLog(@"injected code loaded");
    gInjectedCode = [[Injected alloc] init];
    
    [gInjectedCode installMenu];
}

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

- (IBAction)testAction:(id)sender
{
    NSLog(@"test action fired");
}

@end

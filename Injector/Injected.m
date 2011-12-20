#import "Injected.h"
#import <AppKit/AppKit.h>

@interface Injected()

- (IBAction)testAction:(id)sender;

@end

@implementation Injected

+ (void)load 
{
    NSLog(@"i am in you");
    
    NSMenu* menu = [[NSApplication sharedApplication] mainMenu];
    NSLog(@"got menu %@", menu);
    
    NSInteger index = [menu indexOfItemWithTitle:@"Injector"];
    if (index == -1)
    {
        NSMenuItem* injectorItem = [menu addItemWithTitle:@"Injector" action:nil keyEquivalent:@""];
        NSLog(@"adding item %@", injectorItem);

        NSMenu* injectorMenu = [[NSMenu alloc] initWithTitle:@"Injector"];
        NSLog(@"adding menu %@", injectorMenu);
        
        NSMenuItem* testItem = [injectorMenu addItemWithTitle:@"Test" action:@selector(testAction:) keyEquivalent:@""];
        testItem.target = self;
        
        [injectorItem setSubmenu:injectorMenu];
        [injectorMenu release];
        
        NSLog(@"menu added");
    }
}

- (IBAction)testAction:(id)sender
{
    NSLog(@"test action fired");
}

@end

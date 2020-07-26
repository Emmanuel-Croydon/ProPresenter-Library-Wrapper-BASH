//
//  AppDelegate.m
//  ProPresenter Library Wrapper
//
//  Created by Jonathan Mash on 10/05/2020.
//  Copyright © 2020 Jonathan Mash. All rights reserved.
//

#import "AppDelegate.h"

#define kASAppleScriptSuite 'ascr'
#define kASSubroutineEvent  'psbr'
#define keyASSubroutineName 'snam'

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    if ([[NSRunningApplication runningApplicationsWithBundleIdentifier:[[NSBundle mainBundle] bundleIdentifier]] count] > 1) {
        [self showErrorDialogue:[NSString stringWithFormat:@"%@ is already running.", [NSBundle mainBundle]] informativeText:@"This instance will now quit."];
        [NSApp terminate:nil];
    }
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [[[NSWorkspace sharedWorkspace] notificationCenter]
     addObserver:self
     selector:@selector(appQuitNotification:)
     name:@"NSWorkspaceDidTerminateApplicationNotification"
     object:nil];
    [self runInteractiveTerminalApp:[[NSBundle mainBundle] pathForResource:@"startupWorker" ofType:@"sh"]];
}

- (void)appQuitNotification:(NSNotification *)anotification {
    NSString *appName = [[anotification userInfo][NSWorkspaceApplicationKey] localizedName];
    
    if([appName isEqualToString:(@"ProPresenter")]) {
        [self runInteractiveTerminalApp:[[NSBundle mainBundle] pathForResource:@"terminationWorker" ofType:@"sh"]];
        [NSApp terminate:nil];
    } else {
        // Do nothing
    }
}

- (void)showErrorDialogue:(NSString *)messageText informativeText:(NSString *)informativeText {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:messageText];
    [alert setInformativeText:informativeText];
    [alert addButtonWithTitle:@"Ok"];
    [alert runModal];
}

- (void)runInteractiveTerminalApp:(NSString *)scriptPath {
    NSDictionary *errors = [NSDictionary dictionary];
    // load the script from a resource by fetching its URL from within our bundle
    NSString *path = [[NSBundle mainBundle] pathForResource:@"RunInteractiveShell" ofType:@"scpt"];
    
    if (path != nil) {
        NSURL *url = [NSURL fileURLWithPath:path];
        
        if (url != nil) {
            NSAppleScript *appleScript = [[NSAppleScript alloc] initWithContentsOfURL:url error:&errors];
            
            if (appleScript != nil) {
                // create and populate the list of parameters
                NSAppleEventDescriptor *parameters = [NSAppleEventDescriptor listDescriptor];
                [parameters insertDescriptor:[NSAppleEventDescriptor descriptorWithString:scriptPath] atIndex:1];
                
                // create the AppleEvent target
                ProcessSerialNumber psn = {0, kCurrentProcess};
                NSAppleEventDescriptor *target = [NSAppleEventDescriptor  descriptorWithDescriptorType:typeProcessSerialNumber bytes:&psn  length:sizeof(ProcessSerialNumber)];
                
                // create an NSAppleEventDescriptor with the script's method name to call
                NSAppleEventDescriptor *handler = [NSAppleEventDescriptor descriptorWithString: [@"runinteractiveterminalapp" lowercaseString]];

                // create the event for an AppleScript subroutine
                NSAppleEventDescriptor *event = [NSAppleEventDescriptor appleEventWithEventClass:kASAppleScriptSuite eventID:kASSubroutineEvent targetDescriptor:target returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];
                
                [event setParamDescriptor:handler forKeyword:keyASSubroutineName];
                [event setParamDescriptor:parameters forKeyword:keyDirectObject];
                
                // call the event in AppleScript
                NSAppleEventDescriptor *result =[appleScript executeAppleEvent:event error:&errors];
                int returnCode = [[result stringValue] intValue];

                if ([errors count] > 0 || returnCode != 0) {
                    [self showErrorDialogue:@"An error has occurred with the ProPresenter Library sync scripts" informativeText:@"Please provide the contents of the terminal window to support."];
                    NSLog(@"ProPresenter Library Wrapper sync scripts have finished abnormally with return code: %d", returnCode);
                    NSLog(@"ProPresenter Library Wrapper errors: %@", errors);
                    [NSApp terminate:nil];
                }
            } else {
                [self showErrorDialogue:@"An error has occurred with the installation of ProPresenter Library wrapper" informativeText:@"Please contact support."];
                NSLog(@"ProPresenter Library Wrapper unable to locate AppleScript at: %@", url);
                NSLog(@"ProPresenter Library Wrapper errors: %@", errors);
                [NSApp terminate:nil];
            }
        } else {
            [self showErrorDialogue:@"An error has occurred with the installation of ProPresenter Library wrapper" informativeText:@"Please contact support."];
            NSLog(@"ProPresenter Library Wrapper unable to locate AppleScript at: %@", path);
            [NSApp terminate:nil];
        }
    } else {
        [self showErrorDialogue:@"An error has occurred with the installation of ProPresenter Library wrapper" informativeText:@"Please contact support."];
        NSLog(@"ProPresenter Library Wrapper unable to locate RunInteractiveShell in resource bundle.");
        [NSApp terminate:nil];
    }
}

@end

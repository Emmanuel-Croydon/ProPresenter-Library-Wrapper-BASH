//
//  main.m
//  ProPresenter Library Wrapper
//
//  Created by Jonathan Mash on 10/05/2020.
//  Copyright © 2020 Jonathan Mash. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSApplication *application = [NSApplication sharedApplication];
        AppDelegate *appDelegate = [[AppDelegate alloc] init];
        [application setDelegate:appDelegate];
        [application run];
    }
    return EXIT_SUCCESS;
}

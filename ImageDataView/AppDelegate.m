//
//  AppDelegate.m
//  ImageDataView
//
//  Created by Oliver Zscheyge on 6/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "BAImageDataViewController.h"

@implementation AppDelegate

@synthesize window = _window;

- (void)dealloc
{
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    BAImageDataViewController* imageDataViewController = [[BAImageDataViewController alloc] initWithNibName:@"BAImageDataView" bundle:nil];
//    system("pwd");
    [imageDataViewController loadView];
    
    [self.window setContentView:[imageDataViewController view]];
}

@end

//
//  AppDelegate.m
//  ImageDataView
//
//  Created by Oliver Zscheyge on 6/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "BAImageDataViewController.h"

#import "EDDataElement.h"

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
    
    
    
    
    // TODO: hardcoded image
    EDDataElement* image = [[EDDataElement alloc] initWithDataFile:@"/Users/olli/test/reg3d_test/mni_lipsia.nii" 
                                                         andSuffix:@"" 
                                                        andDialect:@"" 
                                                       ofImageType:IMAGE_ANADATA];
    
    [imageDataViewController showImage:nil];
    sleep(15);
    [imageDataViewController showImage:image];
    
}

@end

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
    EDDataElement* background = [[EDDataElement alloc] initWithDataFile:@"/Users/olli/test/reg3d_test_scansoliver/14265.5c_ana_mdeft.nii" 
                                                              andSuffix:@"" 
                                                             andDialect:@"" 
                                                            ofImageType:IMAGE_ANADATA];
    
//    EDDataElement* background = [[EDDataElement alloc] initWithDataFile:@"/Users/olli/test/reg3d_test_scansoliver/14265.5c_fun_coronar_64x64.nii" 
//                                                              andSuffix:@"" 
//                                                             andDialect:@"" 
//                                                            ofImageType:IMAGE_FCTDATA];
    
    EDDataElement* image = [[EDDataElement alloc] initWithDataFile:@"/Users/olli/test/reg3d_test_scansoliver/14265.5c_fun_sagittal_64x64.nii" 
                                                         andSuffix:@"" 
                                                        andDialect:@"" 
                                                       ofImageType:IMAGE_FCTDATA];
    
    [imageDataViewController setBackgroundImage:background];
    [imageDataViewController addOverlayImage:image withID:@"funData"];
    
//    [imageDataViewController release];
//    [image release];
//    [background release];
    
//    [imageDataViewController showImage:image];
    
}

@end

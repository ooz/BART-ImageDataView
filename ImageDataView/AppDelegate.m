//
//  AppDelegate.m
//  ImageDataView
//
//  Created by Oliver Z. on 6/20/12.
//  Copyright (c) 2012 MPI CBS. All rights reserved.
//

#import "AppDelegate.h"
#import "BAImageDataViewController.h"
#import "BAROIController.h"

#import "EDDataElement.h"


@implementation AppDelegate

@synthesize window = _window;

- (void)dealloc
{
    [super dealloc];
}

// ###################################################
// # Example context for embedding a BrainImageView. #
// ###################################################
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    BAImageDataViewController* imageDataViewController = [[BAImageDataViewController alloc] init];
    
    [imageDataViewController loadView];
    
    [self.window setContentView:[imageDataViewController view]];
    
    // TODO: hardcoded image
//    EDDataElement* background = [[EDDataElement alloc] initWithDataFile:@"/Users/olli/test/reg3d_test_scansoliver/14265.5c_ana_mdeft.nii" 
//                                                              andSuffix:@"" 
//                                                             andDialect:@"" 
//                                                            ofImageType:IMAGE_ANADATA];
    
    EDDataElement* background = [[EDDataElement alloc] initWithDataFile:@"/Users/olli/test/reg3d_test_scansoliver/14265.5c_fun_sagittal_64x64.nii" 
                                                              andSuffix:@"" 
                                                             andDialect:@"" 
                                                            ofImageType:IMAGE_FCTDATA];
    
    EDDataElement* image = [[EDDataElement alloc] initWithDataFile:@"/Users/olli/test/reg3d_test_scansoliver/14265.5c_fun_sagittal_64x64.nii" 
                                                         andSuffix:@"" 
                                                        andDialect:@"" 
                                                       ofImageType:IMAGE_FCTDATA];
    
    [imageDataViewController setBackgroundImage:background];
    [imageDataViewController addOverlayImage:image withID:@"funData"];
    
    // For ROI testing purposes
    [[imageDataViewController getROIController] addROI:@"TestROI"];
    [[imageDataViewController getROIController] addROI:@"ROI2"];
    [[imageDataViewController getROIController] addROI:@"TestoROI"];
    [[imageDataViewController getROIController] removeROI:@"ROI2"];
    
//    [imageDataViewController release];
//    [image release];
//    [background release];
}

@end

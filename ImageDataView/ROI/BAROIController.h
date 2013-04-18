//
//  BAROIController.h
//  ImageDataView
//
//  Created by Oliver Zscheyge on 4/18/13.
//
//

#import <Cocoa/Cocoa.h>

/** 
 * Controller for BAROIToolboxView.xib
 * Manages selection of ROIs
 */
@interface BAROIController : NSController {
    
}


@property (readonly) IBOutlet NSSegmentedControl* mToolSelect;
@property (readonly) IBOutlet NSSegmentedControl* mModeSelect;
@property (readonly) IBOutlet id                  mROISelect;

@property (readonly) IBOutlet NSTextField*        mThresholdField;
@property (readonly) IBOutlet NSStepper*          mThresholdStepper;


-(IBAction)setTool:(id)sender;
-(IBAction)setMode:(id)sender;
-(IBAction)setROI:(id)sender;
-(IBAction)setThreshold:(id)sender;

@end

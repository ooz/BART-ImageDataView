//
//  BAROIController.h
//  ImageDataView
//
//  Created by Oliver Zscheyge on 4/18/13.
//
//

#import <Cocoa/Cocoa.h>

#import "BADataClickHandling.h"
#import "BAROISelection.h"

/** 
 * Controller for BAROIToolboxView.xib
 * Manages selection of ROIs
 */
@interface BAROIController : NSViewController <BADataClickHandling> {
    
    NSMutableDictionary* mROIs;
    enum ROISelectionMode mMode;
    float mThreshold;
    
}

// ###################################
// # GUI related outlets and actions #
// ###################################
@property (readonly) IBOutlet NSSegmentedControl* mToolSelect;
@property (readonly) IBOutlet NSSegmentedControl* mModeSelect;
@property (readonly) IBOutlet id                  mROISelect;

@property (readonly) IBOutlet NSTextField*        mThresholdField;
@property (readonly) IBOutlet NSStepper*          mThresholdStepper;


-(IBAction)setTool:(id)sender;
-(IBAction)setMode:(id)sender;
-(IBAction)setROI:(id)sender;
-(IBAction)setThreshold:(id)sender;


// ###################
// # Regular methods #
// ###################

/** Acknowledges a new ROI label to the controller.
 *
 * \param label NSString name of the new ROI.
 */
-(void)addROI:(NSString*)label;

/** Deletes a ROI (and all information associated with it) from the controller.
 *
 * \param label NSString name of the ROI to remove.
 */
-(void)removeROI:(NSString*)label;

/** Converts a ROI to a binary mask.
 *
 * \param roiLabel NSString name of the ROI to convert.
 * \return         EDDataElement being a binary mask (voxel values of 0.0 and 1.0).
 *                 Nil if no ROI with the name roiLabel exists.
 */
-(EDDataElement*)roiAsBinaryMask:(NSString*)roiLabel;

@end

//
//  BAROIController.h
//  ImageDataView
//
//  Created by Oliver Z. on 4/18/13.
//
//

#import <Cocoa/Cocoa.h>

#import "BADataClickHandling.h"
#import "BAROISelection.h"

@class BADataElementRenderer;

/** 
 * Controller for BAROIToolboxView.xib
 * Manages selection of ROIs and updates on the renderer used to display the ROI selection
 * in the view.
 */
@interface BAROIController : NSViewController <BADataClickHandling> {
    
    /** Renderer used to convert the ROI mask (EDDataElement) to a displayable NSImage. */
    BADataElementRenderer* mROISelectionRenderer;
    
    /** Key: ROI name, value: BAROISelection */
    NSMutableDictionary* mROISelections;
    /** Key: ROI name, value: rendered mask (EDDataElement) */
    NSMutableDictionary* mROIMasks;
    
    enum ROISelectionMode mMode;
    float mThreshold;
    
}


// ###################################
// # GUI related outlets and actions #
// ###################################

@property (readonly) IBOutlet NSSegmentedControl* mToolSelect;
@property (readonly) IBOutlet NSSegmentedControl* mModeSelect;
@property (readonly) IBOutlet id                  mROISelect;

-(IBAction)setTool:(id)sender;
-(IBAction)setMode:(id)sender;
-(IBAction)setROI:(id)sender;


// ################
// # Initializers #
// ################

/** Initializer.
 * Acknowledges the renderer used to convert the ROI mask (EDDataElement)
 * to a displayable NSImage.
 *
 * \param r BADataElementRenderer.
 */
-(id)initWithROISelectionRenderer:(BADataElementRenderer*)r;


// ###################
// # Regular methods #
// ###################

/** Adds a new ROI label to the controller.
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

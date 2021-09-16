//
//  BAImageData.h
//  ImageDataView
//
//  Created by Oliver Z. on 6/21/12.
//  Copyright (c) 2012 MPI CBS. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import "EDDataElement.h"

@class BAROIController;
@class BADataElementRenderer;
@class BABrainImageView;
@class BAImageSliceSelector;

/**
 * Controller for an ImageDataView.
 * The view can be used to display volume data in various orientations
 * in either a single slice view or multi slice grid.
 */
@interface BAImageDataViewController : NSViewController {
    
    /** Subcontroller managing ROIs and ROI selection. */
    BAROIController* mROIController;
    /** Window containing the ROI selection view controlled by */
    NSWindow* mROIToolboxWindow;
    
    /** Renderer used to convert an EDDataElement to a NSImage. */
    BADataElementRenderer* mRenderer;
    
    /** Renderer for overlays. */
    BADataElementRenderer* mOverlayRenderer;
    
    /** Renderer for voxel selections (e.g. ROIs) on overlays or the background. */
    BADataElementRenderer* mSelectionRenderer;
    
    /** Dictionary mapping IDs to EDDataElement objects. */
    NSMutableDictionary* mOverlays;
    
    /** Size of the multi slice grid. */
    NSSize mGridSize;
}

/** Custom NSView providing overlay functionality. */
@property (readonly) IBOutlet BABrainImageView*   mImageView;

/** Component for selecting different image orientations (axial, sagittal, coronal).*/
@property (readonly) IBOutlet NSSegmentedControl* mOrientationSelect;
/** Drop down menu to select the grid size for the multi slice view. */
@property (readonly) IBOutlet id                  mGridSizeSelect;
/** Text field used to select a slice. */
@property (readonly) IBOutlet NSTextField*        mSliceSelect;
/** Slider used to select a slice. */
@property (readonly) IBOutlet NSSlider*           mSliceSelectSlider;

/** Basic (= non overlay related) view actions. */
-(IBAction)setOrientation:(id)sender;
-(IBAction)setGridSize:(id)sender;
-(IBAction)selectSlice:(id)sender;



// ###########################################
// # Overlay related properties and methods. #
// ###########################################


/** Sets the background EDDataElement (usually anatomical data or the MNI template). */
-(void)setBackgroundImage:(EDDataElement*)image;

/** Adds an EDDataElement to the list of potential overlays.
 * To activate/show an overlay you need explicitly call BAImageDataViewController#showOverlay: 
 * 
 * \param image      EDDataElement representing the overlay data.
 * \param identifier NSString ID shown in the overlay selection drop down.
 */
-(void)addOverlayImage:(EDDataElement*)image withID:(NSString*)identifier;

/** Removes an EDDataElement from the list of potential overlays. 
 *
 * \param identifier NSString ID associated with the EDDataElement to remove. */
-(void)removeOverlay:(NSString*)identifier;

/** Shows/activates an overlay by its ID. 
 *
 * \param identifier NSString ID of the overlay to show. */
-(void)showOverlay:(NSString*)identifier;
/** Hides/deactivates an overlay by its ID.
 *
 * \param identifier NSString ID of the overlay to hide. */
-(void)hideOverlay:(NSString*)identifier;

/** Getter for overlay IDs. */
-(NSArray*)overlayIDs;
/** Gets the EDDataElement for an overlay ID. */
-(EDDataElement*)getOverlayBy:(NSString*)identifier;



// ################################################
// # Outlets and actions for overlays/colortables #
// ################################################

/** # Bindings for the region selection components (text fields and steppers). # */
@property (nonatomic, readwrite) float mRegion1Lower;
@property (nonatomic, readwrite) float mRegion1Upper;
@property (nonatomic, readwrite) float mRegion2Lower;
@property (nonatomic, readwrite) float mRegion2Upper;

/** Drop down to select the overlay to use. */
@property (readonly) IBOutlet NSPopUpButton*      mOverlaySelect;
/** Drop down to select the colortable to apply to the overlay. */
@property (readonly) IBOutlet NSPopUpButton*      mColortableSelect;

/** # Color table region selection components. # */
/** Color table region 1. */
@property (readonly) IBOutlet NSTextField*        mRegion1LowerField;
@property (readonly) IBOutlet NSStepper*          mRegion1LowerStepper;
@property (readonly) IBOutlet NSTextField*        mRegion1UpperField;
@property (readonly) IBOutlet NSStepper*          mRegion1UpperStepper;
/** Color table region 2. */
@property (readonly) IBOutlet NSTextField*        mRegion2LowerField;
@property (readonly) IBOutlet NSStepper*          mRegion2LowerStepper;
@property (readonly) IBOutlet NSTextField*        mRegion2UpperField;
@property (readonly) IBOutlet NSStepper*          mRegion2UpperStepper;

/** Overlay related actions. */
-(IBAction)setOverlay:(id)sender;
-(IBAction)setColortable:(id)sender;
-(IBAction)setRegion1Bounds:(id)sender;
-(IBAction)setRegion2Bounds:(id)sender;



// ###################################
// # ROI related outlets and actions #
// ###################################

/** Binding for a button to show/hide the ROI toolbox window + view. */
@property (readonly) IBOutlet id mROIToolboxButton;

/** ROI related actions */
-(IBAction)toggleROIToolbox:(id)sender;

/** Getter. */
-(BAROIController*)getROIController;

@end

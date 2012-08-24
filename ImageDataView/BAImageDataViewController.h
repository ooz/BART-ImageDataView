//
//  BAImageData.h
//  ImageDataView
//
//  Created by Oliver Zscheyge on 6/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import "EDDataElement.h"

@class BADataElementRenderer;
@class BABrainImageView;
@class BAImageSliceSelector;

/**
 * Controller for an ImageDataView.
 * The view can be used to display volume data in various orientations
 * in either a single slice view or multi slice grid.
 */
@interface BAImageDataViewController : NSViewController {
    
    /** Renderer used to convert an EDDataElement to a NSImage. */
    BADataElementRenderer* mRenderer;
    
    /** Size of the multi slice grid. */
    NSSize mGridSize;
}


@property (readonly) IBOutlet BABrainImageView*   mImageView;

@property (readonly) IBOutlet NSSegmentedControl* mOrientationSelect;
@property (readonly) IBOutlet id                  mGridSizeSelect;
@property (readonly) IBOutlet NSTextField*        mSliceSelect;
@property (readonly) IBOutlet NSSlider*           mSliceSelectSlider;

-(IBAction)setOrientation:(id)sender;
-(IBAction)setGridSize:(id)sender;
-(IBAction)selectSlice:(id)sender;

/** Displays an image.
 * Convenience method for \see{BAImageDataViewController#showImage:slice:atTimestep:}.
 * Shows the first slice of the first timestep.
 *
 * \see{BAImageDataViewController#showImage:slice:atTimestep:}
 */
-(void)showImage:(EDDataElement*)image;

/** Displays an image.
 * Shows a volume from an image object at the specified timestep.
 * Depending on the view state (either single or multi slice view) the parameter
 * sliceNr is evaluated. It is non-relevant for the multi slice grid.
 *
 * \param image   EDDataElement to display.
 * \param sliceNr The slice of the volume of image at tstep to display. 
 *                Value is ignored if view is in multi slice state.
 * \param tstep   Timestep/volume of image to display.
 */
-(void)showImage:(EDDataElement*)image
           slice:(uint)sliceNr
      atTimestep:(uint)tstep;

@end

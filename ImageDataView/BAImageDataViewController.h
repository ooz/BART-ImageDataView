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

@class BAImageSliceSelector;

/**
 * Controller for an ImageDataView.
 * The view can be used to display volume data in various orientations
 * in either a single slice view or multi slice grid.
 */
@interface BAImageDataViewController : NSViewController {
    
    /** The volume data to be shown. */
    EDDataElement* mImage;
    /** Min and max value of \see{BAImageDataViewController#mImage} cached for performance reasons. */
    NSArray*       mImageMinMax;
    /** Voxel gap  of \see{BAImageDataViewController#mImage}. */
    NSArray*       mVoxelGap;
    /** Voxel size of \see{BAImageDataViewController#mImage}. */
    NSArray*       mVoxelSize;
    /** Column vector indicating flips/rotations in the y-coord of \see{BAImageDataViewController#mImage}. */
    NSArray*       mColumnVec;
    /** Row    vector indicating flips/rotations in the x-coord of \see{BAImageDataViewController#mImage}. */
    NSArray*       mRowVec;
    
    /** 
     * Property list used to query \see{BAImageDataViewController#mImage} for various traits
     * like voxel size/gap.
     */
    NSArray*       mPropList;
    
    
    /** Filter that decides which slices to display in the multi slice grid. */
    BAImageSliceSelector* mRelevantSliceFilter;
    /** An array containing the filtered slice indices as NSNumber objects. */
    NSArray* mRelevantSlices;
    /** Current slice index to display in a single slice view. 
     * Depends on image size and current \see{BAImageDataViewController#mViewOrientation}. 
     */
    uint mCurrentSlice;
    /** Number of slices in \see{BAImageDataViewController#mImage}. 
     * Depends on image size and current \see{BAImageDataViewController#mViewOrientation}. 
     */
    uint mSliceCount;
    /** The timestep indicating the volume to display. */
    uint mCurrentTimestep;
   
    
    /** Which orientation to display in the view. */
    enum ImageOrientation mViewOrientation;
    /** Main orientation of \see{BAImageDataViewController#mImage}. */
    enum ImageOrientation mMainOrientation;
    
    /** Size of the multi slice grid. */
    NSSize mGridSize;

}


@property (readonly) IBOutlet NSImageView*        mImageView;

@property (readonly) IBOutlet NSSegmentedControl* mOrientationSelect;
@property (readonly) IBOutlet id                  mGridSizeSelect;
@property (readonly) IBOutlet NSTextField*        mSliceSelect;
@property (readonly) IBOutlet NSSlider*           mSliceSelectSlider;

-(IBAction)setOrientation:(id)sender;
-(IBAction)setGridSize:(id)sender;
-(IBAction)selectSlice:(id)sender;

/** Displays an image.
 * Convenience method for \see{BAImageDataViewController#showImage:slice:atTimestep:}.
 * Shows the first slice of the timestep.
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

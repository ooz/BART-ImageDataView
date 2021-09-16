//
//  BADataElementRenderer.h
//  ImageDataView
//
//  Created by Oliver Z. on 8/24/12.
//  Copyright (c) 2012 MPI CBS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EDDataElement.h"

@class BAImageFilter;
@class BAImageSliceSelector;

/** Class used to convert an EDDataElement to a displayable NSImage. */
@interface BADataElementRenderer : NSObject {
    
    /** The volume data to be rendered. */
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
    
    /** 
     * Cache of rendered image in case the raw data (+ slice and orientation info) did not change.
     * (Is used when filter attributes change, so no need to render raw EDDataElement again.)
     */
    CIImage*       mRenderCache;
    /** Flag telling that EDDataElement mImage needs to be rendered as CIImage. */ 
    BOOL           mNeedToRender;
    /** Image filter for the raw rendered image (e.g. a colortable filter). */
    BAImageFilter* mImageFilter;
    
    /** Filter that decides which slices to render in the multi slice grid. */
    BAImageSliceSelector* mRelevantSliceFilter;
    /** An array containing the filtered slice indices as NSNumber objects. */
    NSArray* mRelevantSlices;
    
    /** Current slice index to render in a single slice image. 
     * Depends on image size and current \see{BAImageDataViewController#mTargetOrientation}. 
     */
    uint mCurrentSlice;
    /** Number of slices in \see{BAImageDataViewController#mImage}. 
     * Depends on image size and current \see{BAImageDataViewController#mTargetOrientation}. 
     */
    uint mSliceCount;
    /** The timestep indicating the volume to render. */
    uint mCurrentTimestep;
    /** Total number of timesteps in mImage. */
    uint mTimestepCount;
    
    
    /** Target orientation to which the image should be rendered. */
    enum ImageOrientation mTargetOrientation;
    /** Main orientation of \see{BAImageDataViewController#mImage}. */
    enum ImageOrientation mMainOrientation;
    
    /** Size of the multi slice grid. */
    NSSize mGridSize;
    
}

/** Initializer.
 *
 * \param selector BAImageSliceSelector determining the slices to render
 *                 in case a multi slice image grid should be rendered. */
-(id)initWithSliceSelector:(BAImageSliceSelector*)selector;

/** Convenience method for BADataElementRenderer#setData:slice:timestep
 * Sets the EDDataElement at the current slice/timestep stored in this renderer object.
 * (default: first slice/timestep) 
 */
-(void)setData:(EDDataElement*)elem;

/** Sets the EDDataElement to convert to an NSImage. 
 *
 * \param elem    EDDataElement to set.
 * \param sliceNr Slice to render. 0 marks the first slice. Target orientation dependent.
 * \param tstep   Timestep to render the EDDataElement mImage at.
 */
-(void)setData:(EDDataElement*)elem
         slice:(uint)sliceNr
      timestep:(uint)tstep;

/** Set the slice to render.
 * The number of slices depends on the main (image inherent) and target (render) image orientation. 
 *
 * \param sliceNr Slice to render. 0 marks the first slice. */
-(void)setSlice:(uint)sliceNr;
/** Set the timestep to render.
 *
 * \param tstep Timestep to render the EDDataElement mImage at. */
-(void)setTimestep:(uint)tstep;

/** Sets the size of the slice grid to render.
 * If only one slice should be rendered, pass a size of (1, 1).
 *
 * \param size NSSize of the slice grid to render. */
-(void)setGridSize:(NSSize)size;

/** Set the target (render) image orientation.
 * Depending on the main image orientation and the target orientation the slice dimension might change
 * or the rendering process might be less efficient.
 *
 * \param o Target image orientation. */
-(void)setTargetOrientation:(enum ImageOrientation)o;

/** Sets the filter to apply to the image after it is rendered 
 *  but before it is converted (wrapped) to an NSImage.
 *
 * \param filter BAImageFilter to apply to the rendered image. */
-(void)setImageFilter:(BAImageFilter*)filter;

/** # Getters. # */
-(EDDataElement*)getDataElement;
-(NSArray*)getDataMinMax;
-(uint)getCurrentSlice;
-(uint)getSliceCount;
-(uint)getCurrentTimestep;
-(BAImageFilter*)getImageFilter;

/** Renders the set EDDataElement (#mImage) to an autoreleased NSImage respecting 
 *  previously set parameters like slice/timestep numbers or the grid size.
 *
 *  If a BAImageFilter is set it is applied to the image before returning.
 *
 * \return Autoreleased NSImage.
 */
-(NSImage*)renderImage;


@end

//
//  BADataElementRenderer.h
//  ImageDataView
//
//  Created by Oliver Zscheyge on 8/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EDDataElement.h"

@class BAImageFilter;
@class BAImageSliceSelector;

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

-(id)initWithSliceSelector:(BAImageSliceSelector*)selector;

-(void)setData:(EDDataElement*)elem;

-(void)setData:(EDDataElement*)elem
         slice:(uint)sliceNr
      timestep:(uint)tstep;

-(void)setSlice:(uint)sliceNr;
-(void)setTimestep:(uint)tstep;

-(void)setGridSize:(NSSize)size;
-(void)setTargetOrientation:(enum ImageOrientation)o;

-(void)setImageFilter:(BAImageFilter*)filter;

-(EDDataElement*)getDataElement;
-(NSArray*)getDataMinMax;
-(uint)getCurrentSlice;
-(uint)getSliceCount;
-(uint)getCurrentTimestep;

-(BAImageFilter*)getImageFilter;

/**
 * \return Autoreleased NSImage.
 */
-(NSImage*)renderImage;


@end

//
//  BAImageDataViewConstants.h
//  ImageDataView
//
//  Created by Oliver Z. on 8/24/12.
//  Copyright (c) 2012 MPI CBS. All rights reserved.
//

#ifndef ImageDataView_BAImageDataViewConstants_h
#define ImageDataView_BAImageDataViewConstants_h

/** Bundle identifier used to locate resources. */
static NSString* BUNDLE_ID = @"de.cbs.mpg.bart.ImageDataView";

/** Number of channels in the rendered NSImage object (RGBA). */
static const int   NUMBER_OF_CHANNELS = 4;
/** Highest alpha value. */
static const float MAX_ALPHA = 1.0f;

/** When multiplied with the image size results in the minimum image size. */
static const float MIN_SCALE_FACTOR = 0.1f;

/** Default grid size for both width and height (single slice). */
static const CGFloat DEFAULT_GRID_SIZE = 1.0f;
/** Grid width/height for a 6x6 slice grid. */
static const CGFloat GRID_SIZE_SIX = 6.0f;

/** \see{EDDataElement} property key to query the voxel gap. */
static NSString* PROP_VOXELGAP  = @"voxelgap";
/** \see{EDDataElement} property key to query the voxel size. */
static NSString* PROP_VOXELSIZE = @"voxelsize";
/** \see{EDDataElement} property key to query the column vector. */
static NSString* PROP_COLUMNVEC = @"columnvec";
/** \see{EDDataElement} property key to query the row vector. */
static NSString* PROP_ROWVEC    = @"rowvec";

/** Threshold for horizontal flipping. 
 *  If first  component of row vector is below this value, the image is flipped. */
static const float ROW_FLIP_THRESHOLD = 0.0f;
/** Threshold for vertical flipping. 
 *  If second component of col vector is below this value, the image is flipped. */
static const float COL_FLIP_THRESHOLD = 0.0f;

#endif

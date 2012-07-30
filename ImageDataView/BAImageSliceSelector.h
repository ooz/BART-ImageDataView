//
//  BAImageSliceSelector.h
//  ImageDataView
//
//  Created by Oliver Zscheyge on 7/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EDDataElement.h"

/**
 * Enum indicating volume dimensions.
 */
enum ImageDimension {
      DIM_WIDTH
    , DIM_HEIGHT
    , DIM_SLICE
};

/** A slice selector filters relevant slices from a given volume.
 * Subclasses should override the \see{BAImageSliceSelector#select:slicesFrom:alignedTo} method.
 */
@interface BAImageSliceSelector : NSObject

/**
 * Returns a 3-dimensional array of original image dimensions
 * corresponding to (DIM_WIDTH, DIM_HEIGHT, DIM_SLICE) in the target image space.
 * 
 * E.g. a sagittal image that should be aligned to axial orientation would return
 * an array containing (DIM_SLICE, DIM_WIDTH, DIM_HEIGHT).
 *
 * \param image       EDDataElement. It's main orientation combined with the parameter
 *                    orientation determine the returned array.
 * \param orientation Target orientation. Determines the returned dimensions 
 *                    together with the image's main orientation.
 * \return            Three-dimensional array of enum ImageDimension (original image dimensions).
 *                    The dimensions denote the x-, y-, z-dimension (in that order) in the target
 *                    image space.
 *                    MEMORY MANAGEMENT: Caller is responsible to free the allocated memory!
 */
-(enum ImageDimension*)getDimensionsFrom:(EDDataElement*)image
                               alignedTo:(enum ImageOrientation)orientation;

/**
 * Returns the size of the "slice dimension" which is determined by the image's
 * main orientation and the target orientation.
 *
 * \param image       EDDataElement whose "slice dimension" is of interest.
 * \param orientation Target orientation. Combined with the image main orientation
 *                    it determines which dimension to treat as the "slice dimension".
 * \return            Size of the "slice dimension".
 */
-(size_t)getSliceDimensionSize:(EDDataElement*)image
                     alignedTo:(enum ImageOrientation)orientation;

/** 
 * Select n slice indices from an EDDataElement viewed from a given
 * orientation.
 * 
 * \param n           Number of slice indices to select.
 * \param image       EDDataElement to evaluate/select slices from.
 * \param orientation Target orientation. Together with the image main orientation
 *                    it determines which dimension to treat as the "slice dimension".
 * \return            NSArray of NSNumber objects representing the selected slices 
 *                    (indices).
 */
-(NSArray*)select:(size_t)n 
       slicesFrom:(EDDataElement*)image
        alignedTo:(enum ImageOrientation)orientation;

@end

//
//  BAImageSliceSelector.h
//  ImageDataView
//
//  Created by Oliver Zscheyge on 7/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EDDataElement.h"

enum ImageDimension {
      DIM_WIDTH
    , DIM_HEIGHT
    , DIM_SLICE
//    , DIM_TIMESTEP
};

@interface BAImageSliceSelector : NSObject

/**
 * Returns a 3-dimensional array of original image dimensions
 * corresponding to (DIM_WIDTH, DIM_HEIGHT, DIM_SLICE) in the target image space.
 * 
 * E.g. a sagittal image that should be aligned to axial orientation would return
 * an array containing (DIM_SLICE, DIM_WIDTH, DIM_HEIGHT).
 *
 * Memory management: callers needs to free the array!
 */
-(enum ImageDimension*)getDimensionsFrom:(EDDataElement*)image
                               alignedTo:(enum ImageOrientation)orientation;

-(NSArray*)select:(size_t)n 
       slicesFrom:(EDDataElement*)image
        alignedTo:(enum ImageOrientation)orientation;

@end

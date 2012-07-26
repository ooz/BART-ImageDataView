//
//  BAImageSliceSelector.m
//  ImageDataView
//
//  Created by Oliver Zscheyge on 7/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BAImageSliceSelector.h"

const size_t RELEVANT_DIMENSIONS = 3;
const size_t SLICE_DIMENSION_INDEX = 2;


//@interface BAImageSliceSelector (__privateMethods__)
//
//
//
//@end


@implementation BAImageSliceSelector

-(size_t)getSliceDimensionSize:(EDDataElement*)image
                     alignedTo:(enum ImageOrientation)orientation
{
    BARTImageSize* imageSize = [image getImageSize]; 
    
    enum ImageDimension* dims = [self getDimensionsFrom:image alignedTo:orientation];
    enum ImageDimension sliceDim = dims[SLICE_DIMENSION_INDEX];
    free(dims);
    
    size_t relevantSize = 0;
    switch (sliceDim) {
        case DIM_WIDTH:
            relevantSize = imageSize.columns;
            break;
        case DIM_HEIGHT:
            relevantSize = imageSize.rows;
            break;
        case DIM_SLICE:
            relevantSize = imageSize.slices;
            break;
        default:
            NSLog(@"Error: could not find relevant slice dimension! Defaulting to 0!");
            break;
    }
    
    return relevantSize;
}

-(enum ImageDimension*)getDimensionsFrom:(EDDataElement*)image
                               alignedTo:(enum ImageOrientation)orientation
{
    enum ImageOrientation mainOrientation = [image getMainOrientation];
    BOOL isSagittal = mainOrientation == ORIENT_SAGITTAL || mainOrientation == ORIENT_REVSAGITTAL;
    BOOL isAxial    = mainOrientation == ORIENT_AXIAL    || mainOrientation == ORIENT_REVAXIAL;
    BOOL isCoronal  = mainOrientation == ORIENT_CORONAL  || mainOrientation == ORIENT_REVCORONAL;
    
    BOOL targetSagittal = orientation == ORIENT_SAGITTAL || orientation == ORIENT_REVSAGITTAL;
    BOOL targetAxial    = orientation == ORIENT_AXIAL    || orientation == ORIENT_REVAXIAL;
    BOOL targetCoronal  = orientation == ORIENT_CORONAL  || orientation == ORIENT_REVCORONAL;
    
    enum ImageDimension* dims = malloc(sizeof(enum ImageDimension) * RELEVANT_DIMENSIONS);
    
    if ((isSagittal && targetSagittal)
        || (isAxial && targetAxial)
        || (isCoronal && targetCoronal)) {
        dims[0] = DIM_WIDTH;
        dims[1] = DIM_HEIGHT;
        dims[2] = DIM_SLICE;
        
    } else if (isSagittal && targetAxial) {
        dims[0] = DIM_SLICE;
        dims[1] = DIM_WIDTH;
        dims[2] = DIM_HEIGHT;
        
    } else if ((isSagittal && targetCoronal)
               || (isCoronal && targetSagittal)) {
        dims[0] = DIM_SLICE;
        dims[1] = DIM_HEIGHT;
        dims[2] = DIM_WIDTH;
        
    } else if (isAxial && targetSagittal) {
        dims[0] = DIM_HEIGHT;
        dims[1] = DIM_SLICE;
        dims[2] = DIM_WIDTH;
    
    } else if ((isAxial && targetCoronal) 
               || (isCoronal && targetAxial)) {
        dims[0] = DIM_WIDTH;
        dims[1] = DIM_SLICE;
        dims[2] = DIM_HEIGHT;
    }
    
    return dims;
}

-(NSArray*)select:(size_t)n 
       slicesFrom:(EDDataElement*)image
        alignedTo:(enum ImageOrientation)orientation
{
    size_t relevantSize = [self getSliceDimensionSize:image alignedTo:orientation];
    
    size_t size;
    if (n <= relevantSize) {
        size = n;
    } else {
        size = relevantSize;
    }
    
    NSMutableArray* relevantSlices = [NSMutableArray arrayWithCapacity:size]; 

    size_t step = relevantSize / size;
    size_t rest = relevantSize % size;
    
    NSInteger i = rest / 2; // Start with a padding
    while (i < relevantSize) {
        [relevantSlices addObject:[NSNumber numberWithInteger:i]];
        i += step;
    }
    
    return relevantSlices;
}

@end

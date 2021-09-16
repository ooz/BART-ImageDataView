//
//  BAImageSliceSelector.m
//  ImageDataView
//
//  Created by Oliver Z. on 7/24/12.
//  Copyright (c) 2012 MPI CBS. All rights reserved.
//

#import "BAImageSliceSelector.h"

/** Default size of the slice dimension. */
const size_t DEFAULT_SLICE_DIMENSION_SIZE = 1;

/** Number of dimensions in one volume. */
const size_t RELEVANT_DIMENSIONS = 3;
/** Index of the "slice dimension" in an array of dimensions. */
const size_t SLICE_DIMENSION_INDEX = 2;



@implementation BAImageSliceSelector

-(size_t)getSliceDimensionSize:(EDDataElement*)image
                     alignedTo:(enum ImageOrientation)orientation
{
    if (image == nil) {
        return DEFAULT_SLICE_DIMENSION_SIZE;
    }
    
    BARTImageSize* imageSize = [image getImageSize]; 
    
    enum ImageDimension* dims = [self getDimensionsFrom:image alignedTo:orientation];
    enum ImageDimension sliceDim = dims[SLICE_DIMENSION_INDEX];
    free(dims);
    
    size_t relevantSize = DEFAULT_SLICE_DIMENSION_SIZE;
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
            NSLog(@"Error: could not find relevant slice dimension (someone extended the enum!) Defaulting to 0!");
            break;
    }
    
    return relevantSize;
}

-(NSUInteger*)getRowColVectorMainComponents:(enum ImageOrientation)mainOrient
{
    BOOL isSagittal = mainOrient == ORIENT_SAGITTAL || mainOrient == ORIENT_REVSAGITTAL;
    BOOL isCoronal  = mainOrient == ORIENT_CORONAL  || mainOrient == ORIENT_REVCORONAL;
    
    NSUInteger* comps = malloc(sizeof(NSUInteger) * 2);
    
    if (isSagittal) {
        comps[0] = 1;
        comps[1] = 2;
    } else if (isCoronal) {
        comps[0] = 0;
        comps[1] = 2;
    } else {
        // Axial or default
        comps[0] = 0;
        comps[1] = 1;
    }
    
    return comps;
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
    size_t size = [self getSliceDimensionSize:image alignedTo:orientation];
    
    size_t relevantSize;
    if (n <= size) {
        relevantSize = n;
    } else {
        relevantSize = size;
    }
    
    NSMutableArray* relevantSlices = [NSMutableArray arrayWithCapacity:relevantSize]; 

    size_t step = size / relevantSize;
    size_t rest = size % relevantSize;
    
    NSInteger  slice = rest / 2; // Start with a padding
    NSUInteger count = 0;
    while (slice < size && count < n) {
        [relevantSlices addObject:[NSNumber numberWithInteger:slice]];
        slice += step;
        count++;
    }
    
    return relevantSlices;
}

@end

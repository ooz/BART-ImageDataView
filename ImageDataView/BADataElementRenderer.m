//
//  BADataElementRenderer.m
//  ImageDataView
//
//  Created by Oliver Z. on 8/24/12.
//  Copyright (c) 2012 MPI CBS. All rights reserved.
//

#import "BADataElementRenderer.h"

#import "BAImageDataViewConstants.h"
#import "BAImageFilter.h"
#import "BAImageSliceSelector.h"
#import "BADataVoxel.h"


// #############
// # Constants #
// #############

const NSUInteger MASK_NO_FLIP = 0;
const NSUInteger MASK_X_FLIP  = 1 << 0;
const NSUInteger MASK_Y_FLIP  = 1 << 1;
const NSUInteger MASK_Z_FLIP  = 1 << 2;


// ###############################
// # Private method declarations #
// ###############################

@interface BADataElementRenderer (__privateMethods__)

/**
 * Updates internal (cached) variables of the view if a new image
 * has been set via \see{BAImageDataViewController#showImage}.
 *
 * \param image EDDataElement whose properties are queried.
 */
-(void)fetchPropsIfUpdated:(EDDataElement*)image;
/**
 * Updates slice indices of slices to be shown in the multi slice grid
 * (selected by \{BAImageDataViewController#mRelevantSliceFilter}).
 * The update is triggered when the view orientation is changed or
 * the view is switched from single to multi slice grid.
 *
 * \param image EDDataElement from which slices should be chosen (at current timestep).
 */
-(void)fetchRelevantSlices:(EDDataElement*)image;

/**
 * Methods to render the CIImage object.
 * Regardless of single or multi slice grid only one CIImage is rendered.
 *
 * Renders the EDDataElement mImage directly according to its main orientation.
 * Used in the following cases (source orientation --> target orientation):
 *   sagittal --> sagittal
 *   axial    --> axial
 *   coronal  --> coronal
 */
-(CIImage*)renderIdenticalImage;
/**
 * Renders the EDDataElement mImage as if the voxel data cuboid would be turned up
 * (rotated 90° along its x-axis).
 * Used in the following cases (source orientation --> target orientation):
 *   axial    --> coronal
 *   coronal  --> axial
 */
-(CIImage*)renderTurnUpImage;
/**
 * Renders the EDDataElement mImage as if the voxel data cuboid would be turned left
 * (rotated 90° along its y-axis) and then rotated right (rotated 90° along its z'-axis).
 * Used in the following case (source orientation --> target orientation):
 *   axial    --> sagittal
 */
-(CIImage*)renderTurnLeftRotateRightImage;
/**
 * Renders the EDDataElement mImage as if the voxel data cuboid would be turned left
 * (rotated 90° along its y-axis).
 * Used in the following cases (source orientation --> target orientation):
 *   sagittal --> coronal
 *   coronal  --> sagittal
 */
-(CIImage*)renderTurnLeftImage;
/**
 * Renders the EDDataElement mImage as if the voxel data cuboid would be turned up
 * (rotated 90° along its x-axis) and then rotated right (rotated 90° along its z'-axis).
 * Used in the following case (source orientation --> target orientation):
 *   sagittal --> axial
 */
-(CIImage*)renderTurnUpRotateRightImage;

/**
 * Utility method for the render methods.
 * Constructs a CIImage object from a float vector. The vector is not freed in the process!
 *
 * \param data Float array containing all needed bytes for all channels.
 * \param len  Length of the data float array.
 * \param bpr  Bytes per row in the resulting image. 
 *             This has to respect the size of the data type (float) as well as the number of channels.
 * \param w    Width  of the target CIImage in pixels.
 * \param h    Height of the target CIImage in pixels.
 * \return     Autoreleased CIImage rendering the float data.
 */
-(CIImage*)imageFromFloat:(float*)data 
                   length:(size_t)len 
              bytesPerRow:(size_t)bpr
                    width:(size_t)w
                   height:(size_t)h;

/**
 * Creates a NSImage from a CIImage.
 *
 * \param ciImage     Source image.
 * \return            NSImage created from the source image.
 */
-(NSImage*)ciImageToNSImage:(CIImage*)ciImage;

/**
 * Updates the size of a NSImage object based on the physical size of the
 * EDDataElement to be rendered. This respects voxel size and gap of the image.
 */
-(NSImage*)fixSizeOf:(NSImage*)image 
                with:(BARTImageSize*)dataSize;

@end



// ##################
// # Implementation #
// ##################

@implementation BADataElementRenderer

@synthesize renderedImage;

-(id)init
{
    if (self = [super init]) {
        self->mImage       = nil;
        self->mImageMinMax = nil;
        self->mVoxelGap    = nil;
        self->mVoxelSize   = nil;
        self->mColumnVec   = nil;
        self->mRowVec      = nil;
        self->mFlipMask    = MASK_NO_FLIP;
        
        self->mPropList = [[NSArray arrayWithObjects: PROP_VOXELGAP
                                                    , PROP_VOXELSIZE
                                                    , PROP_COLUMNVEC
                                                    , PROP_ROWVEC
                                                    , nil] retain];
        
        self->mRenderCache  = nil;
        self->mNeedToRender = YES;
        self->mImageFilter  = nil;
        self->mAlpha        = MAX_ALPHA;
        
        self->mRelevantSliceFilter = [[BAImageSliceSelector alloc] init];
        self->mRelevantSlices = nil;
        
        self->mColumnCount  = 1;
        self->mRowCount     = 1;
        
        self->mCurrentSlice = 0;
        self->mSliceCount   = 1;
        self->mCurrentTimestep = 0;
        self->mTimestepCount   = 1;
        
        self->mTargetOrientation = ORIENT_SAGITTAL;
        self->mMainOrientation   = ORIENT_UNKNOWN;
        
        self->mGridSize    = (NSSize) {DEFAULT_GRID_SIZE, DEFAULT_GRID_SIZE};
        
        self->renderedImage = nil;
    }
    
    return self;
}

-(id)initWithSliceSelector:(BAImageSliceSelector*)selector
{
    if (self = [self init]) {
        if (self->mRelevantSliceFilter != nil) {
            [self->mRelevantSliceFilter release];
        }
        self->mRelevantSliceFilter = [selector retain];
    }
    
    return self;
}

-(void)dealloc
{
    if (self->mImage != nil)       [self->mImage release];
    if (self->mImageMinMax != nil) [self->mImageMinMax release];
    if (self->mVoxelGap != nil)    [self->mVoxelGap release];
    if (self->mVoxelSize != nil)   [self->mVoxelSize release];
    if (self->mColumnVec != nil)   [self->mColumnVec release];
    if (self->mRowVec != nil)      [self->mRowVec release];
    
    if (self->mPropList != nil)    [self->mPropList release];
    
    if (self->mRenderCache != nil) [self->mRenderCache release];
    if (self->mImageFilter != nil) [self->mImageFilter release];
    
    if (self->mRelevantSliceFilter != nil) [self->mRelevantSliceFilter release];
    if (self->mRelevantSlices      != nil) [self->mRelevantSlices      release];
    
    [self->renderedImage release];
    
    [super dealloc];
}

-(void)setData:(EDDataElement*)elem
{
    [self setData:elem slice:self->mCurrentSlice timestep:self->mCurrentTimestep];
}

-(void)setData:(EDDataElement*)elem
         slice:(uint)sliceNr
      timestep:(uint)tstep
{
    if (self->mImage != nil) {
        [self->mImage release];
    }
    
    if (elem == nil) {
        if (self->mImageMinMax != nil) {
            [self->mImageMinMax release];
            self->mImageMinMax = nil;
        }
        self->mImage = nil;
        
    } else {
        [self fetchPropsIfUpdated:elem];
        
        self->mImage = elem;
        [self->mImage retain];
        
        [self setTargetOrientation:self->mTargetOrientation];
        [self setSlice:sliceNr];
        [self setTimestep:tstep];
        
        [self setGridSize:self->mGridSize];
    }
    
    self->mNeedToRender = YES;
}

-(void)setSlice:(uint)sliceNr
{
    if (sliceNr < self->mSliceCount) {
        self->mCurrentSlice = sliceNr;
    } else {
        self->mCurrentSlice = 0;
    }
    
    self->mNeedToRender = YES;
}

-(void)setTimestep:(uint)tstep
{
    if (tstep < self->mTimestepCount) {
        self->mCurrentTimestep = tstep;
    }
    
    self->mNeedToRender = YES;
}

-(void)setGridSize:(NSSize)size
{
    self->mGridSize = size;
    
    BOOL isSingleSliceView = self->mGridSize.width == 1 && self->mGridSize.height == 1;
    if (!isSingleSliceView) {
        [self fetchRelevantSlices:self->mImage];
    }
    
    self->mNeedToRender = YES;
}

-(void)setTargetOrientation:(enum ImageOrientation)o
{
    self->mTargetOrientation = o;
    
    size_t* dimSizes = [self->mRelevantSliceFilter getDimensionSizes:self->mImage
                                                           alignedTo:self->mTargetOrientation];
    self->mColumnCount = (uint) dimSizes[0];
    self->mRowCount    = (uint) dimSizes[1];
    self->mSliceCount  = (uint) dimSizes[2];
    free(dimSizes);
    
    [self setSlice:self->mCurrentSlice];
    [self setGridSize:self->mGridSize];
}

-(void)setImageFilter:(BAImageFilter*)filter
{
    if (self->mImageFilter != nil) 
        [self->mImageFilter release];
    
    if (filter != nil) {
        self->mImageFilter = [filter retain];
    } else {
        self->mImageFilter = nil;
    }
}

-(void)setAlpha:(float)alpha
{
    if (alpha < 0.0f) {
        self->mAlpha = MIN_ALPHA;
    } else if (alpha > 1.0f) {
        self->mAlpha = MAX_ALPHA;
    } else {
        self->mAlpha = alpha;
    }
    
    self->mNeedToRender = YES;
}


-(void)fetchPropsIfUpdated:(EDDataElement*)image
{
    if (self->mImage != image) {
        if (self->mImageMinMax != nil) [self->mImageMinMax release];
        self->mImageMinMax = [[image getMinMaxOfDataElement] retain];
        
        self->mMainOrientation = [image getMainOrientation];
        
        BARTImageSize* imageSize = [image getImageSize];
        self->mTimestepCount = imageSize.timesteps;
        
        NSDictionary* imageProps = [image getProps:self->mPropList];
        
        if (self->mVoxelGap != nil) [self->mVoxelGap release];
        self->mVoxelGap = [[imageProps valueForKey:PROP_VOXELGAP] retain];
        
        if (self->mVoxelSize != nil) [self->mVoxelSize release];
        self->mVoxelSize = [[imageProps valueForKey:PROP_VOXELSIZE] retain];
        
        if (self->mColumnVec != nil) [self->mColumnVec release];
        self->mColumnVec = [[imageProps valueForKey:PROP_COLUMNVEC] retain];
        
        if (self->mRowVec != nil) [self->mRowVec release];
        self->mRowVec = [[imageProps valueForKey:PROP_ROWVEC] retain];
        
//        NSLog(@"MainOrientation %d", self->mMainOrientation);
//        NSLog(@"VoxelGap  %@",  self->mVoxelGap);
//        NSLog(@"VoxelSize %@",  self->mVoxelSize);
//        NSLog(@"RowVec %@",     self->mRowVec);
//        NSLog(@"ColumnVec  %@", self->mColumnVec);
    }
}

-(void)fetchRelevantSlices:(EDDataElement*)image
{
    if (self->mRelevantSlices != nil) [self->mRelevantSlices release];
    self->mRelevantSlices = [[self->mRelevantSliceFilter select:self->mGridSize.width * self->mGridSize.height
                                                     slicesFrom:image 
                                                      alignedTo:self->mTargetOrientation] retain]; 
}

-(EDDataElement*)getDataElement
{
    return self->mImage;
}

-(NSArray*)getDataMinMax
{
    return self->mImageMinMax;
}

-(uint)getCurrentSlice
{
    return self->mCurrentSlice;
}

-(uint)getSliceCount
{
    return self->mSliceCount;
}

-(uint)getCurrentTimestep
{
    return self->mCurrentTimestep;
}

-(BAImageFilter*)getImageFilter
{
    return self->mImageFilter;
}

-(float)getAlpha
{
    return self->mAlpha;
}


-(NSImage*)renderImage:(BOOL)force
{
    if (self->mImage == nil) {
        [self setRenderedImage:nil];
        return nil;
    }
    
    if (self->mNeedToRender || force) {
        enum ImageDimension* dims = [self->mRelevantSliceFilter getDimensionsFrom:self->mImage
                                                                        alignedTo:self->mTargetOrientation];
        
        NSUInteger* relevantComps = [self->mRelevantSliceFilter getRowColVectorMainComponents:[self->mImage getMainOrientation]];
        float rowOrientComponent = [[self->mRowVec objectAtIndex:relevantComps[0]] floatValue];
        float colOrientComponent = [[self->mColumnVec objectAtIndex:relevantComps[1]] floatValue];
    //    NSLog(@"Row/col components of row/col-vecs: (%f, %f)", rowOrientComponent, colOrientComponent);
        
        BOOL flipX = rowOrientComponent < ROW_FLIP_THRESHOLD; // x flip in source space
        BOOL flipY;                                           // y flip in source space
        if (relevantComps[1] == 2) {
            // y-axis is top-down in dicom images, while scanner z-axis is bottom-up in coronal images
            flipY = colOrientComponent > COL_FLIP_THRESHOLD; 
        } else {
            flipY = colOrientComponent < COL_FLIP_THRESHOLD;
        }
        free(relevantComps);
        
        self->mFlipMask = MASK_NO_FLIP;                       // flips in target space
        CIImage* renderedSlices;
        switch (dims[0]) {
            case DIM_SLICE:
                switch (dims[1]) {
                    case DIM_HEIGHT:
                        self->mFlipMask = flipY << 1 | flipX << 2;
                        renderedSlices = [self renderTurnLeftImage];
                        break;
                    default:
                        self->mFlipMask = flipX << 1 | flipY << 2;
                        renderedSlices = [self renderTurnUpRotateRightImage];
                        break;
                }
                break;
            case DIM_HEIGHT:
                if (dims[1] == DIM_SLICE) {
                    self->mFlipMask = flipY << 0 | MASK_Y_FLIP | flipX << 2;
                    renderedSlices = [self renderTurnLeftRotateRightImage];
                }
                break;
            default:
                // DIM_WIDTH
                switch (dims[1]) {
                    case DIM_SLICE:
                        self->mFlipMask = flipX << 0 | MASK_Y_FLIP | flipY << 2;
                        renderedSlices = [self renderTurnUpImage];
                        break;
                    default:
                        self->mFlipMask = flipX << 0 | flipY << 1;
                        renderedSlices = [self renderIdenticalImage];
                        break;
                }
                break;
        }
        
        free(dims);
        
        if (self->mRenderCache != nil) 
            [self->mRenderCache release];
        
        self->mRenderCache = [renderedSlices retain];
        [renderedSlices release];
    }
    
    CIImage* ciImage = [self->mRenderCache copy];
    
    // Apply filter
    if (self->mImageFilter != nil) {
        ciImage = [self->mImageFilter apply:ciImage];
    }
    
    NSImage* image = [self ciImageToNSImage:ciImage];
    
    if (self->mImageFilter == nil && ciImage != nil) {
        // If CIFilter based image filter is active, this caused a BadAccess
        [ciImage release];
    }
    
    BARTImageSize* imageSize = [self->mImage getImageSize];
    image = [self fixSizeOf:image with:imageSize];
    
    if (self->mNeedToRender || force) {
        [self setRenderedImage:image];
        self->mNeedToRender = NO;
    }
    
    return image;
}

-(CIImage*)renderIdenticalImage
{
    BARTImageSize* imageSize = [self->mImage getImageSize];
    
    size_t rows       = imageSize.rows;
    size_t cols       = imageSize.columns;
    size_t gridWidth  = self->mGridSize.width;
    size_t gridHeight = self->mGridSize.height;
    
    BOOL flipX = (self->mFlipMask & MASK_X_FLIP) != 0;
    BOOL flipY = (self->mFlipMask & MASK_Y_FLIP) != 0;
    BOOL flipZ = (self->mFlipMask & MASK_Z_FLIP) != 0;
    
    size_t renderImageDataLength =   cols
    * rows 
    * gridWidth
    * gridHeight
    * NUMBER_OF_CHANNELS
    * sizeof(float);
    float* renderImageData = malloc(renderImageDataLength);
    
    float min = [[self->mImageMinMax objectAtIndex:0] floatValue];
    float max = [[self->mImageMinMax objectAtIndex:1] floatValue];
    if (min == max) {
        // Avoid division by 0 later on
        min = 0.0f;
        if (max == 0.0f) max = FLT_MAX;
    }
    float normalized = 0.0f;
    
    if (   gridWidth == 1
        && gridHeight == 1) {
        // Single slice view
        
        uint sliceNr = self->mCurrentSlice;
        if (flipZ) {
            sliceNr = self->mSliceCount - self->mCurrentSlice - 1;
        }
        
        float* sliceData = [self->mImage getSliceData:sliceNr
                                           atTimestep:self->mCurrentTimestep];
        
        size_t srcRow;
        size_t srcCol;
        int targetIndex = 0;
        for (int row = 0; row < rows; row++) {
            for (int col = 0; col < cols; col++) {
                srcRow = (flipY) ? rows - row - 1 : row;
                srcCol = (flipX) ? cols - col - 1 : col;
                normalized = (sliceData[srcRow * cols + srcCol] - min) / (max - min);
                renderImageData[targetIndex++] = normalized;
                renderImageData[targetIndex++] = normalized;
                renderImageData[targetIndex++] = normalized;
                renderImageData[targetIndex++] = self->mAlpha;
            }
        }
        
        free(sliceData);
        
    } else {
        // Many slice view
        // TODO: much space for parallelization here
        
        NSInteger sliceIndex = (flipZ) ? ([self->mRelevantSlices count] - 1) : 0;
        for (int gridRow = 0; gridRow < gridHeight; gridRow++) {
            for (int gridCol = 0; gridCol < gridWidth; gridCol++) {
                
                uint sliceNr   = 0;
                float* sliceData = NULL;
                if (sliceIndex >= 0
                    && sliceIndex < [self->mRelevantSlices count]) {
                    sliceNr   = [[self->mRelevantSlices objectAtIndex:sliceIndex] intValue]; //gridRow * gridWidth + gridCol;
                    sliceData = [self->mImage getSliceData:sliceNr
                                                atTimestep:self->mCurrentTimestep];
                    if (flipZ) {
                        sliceIndex--;
                    } else {
                        sliceIndex++;
                    }
                }
                
                if (sliceData != NULL) {
                    
                    size_t sliceOffset = ((gridRow * gridWidth * cols * rows) + gridCol * cols) * NUMBER_OF_CHANNELS;
                    //                    NSLog(@"SliceNr: %ld, sliceOffset: %ld (rows: %ld, cols: %ld", sliceNr, sliceOffset, rows, cols);
                    
                    size_t srcRow;
                    size_t srcCol;
                    for (size_t row = 0; row < rows; row++) {
                        for (size_t col = 0; col < cols; col++) {
                            srcRow = (flipY) ? (rows - row - 1) : row;
                            srcCol = (flipX) ? (cols - col - 1) : col;
                            normalized = (sliceData[srcRow * cols + srcCol] - min) / (max - min);
                            renderImageData[sliceOffset + (row * gridWidth * cols + col) * NUMBER_OF_CHANNELS]     = normalized;
                            renderImageData[sliceOffset + (row * gridWidth * cols + col) * NUMBER_OF_CHANNELS + 1] = normalized;
                            renderImageData[sliceOffset + (row * gridWidth * cols + col) * NUMBER_OF_CHANNELS + 2] = normalized;
                            renderImageData[sliceOffset + (row * gridWidth * cols + col) * NUMBER_OF_CHANNELS + 3] = self->mAlpha;
                        }
                        
                    }
                    
                    free(sliceData);
                }
            }
        }
    }
    
    CIImage* ciImage = [self imageFromFloat:renderImageData 
                                     length:renderImageDataLength 
                                bytesPerRow:gridWidth * cols * NUMBER_OF_CHANNELS * sizeof(float)
                                      width:gridWidth * cols 
                                     height:gridHeight * rows];
    free(renderImageData);
    
    return ciImage;
}

-(CIImage*)renderTurnUpImage
{
    // TODO: too much c&p from renderIdenticalImage ;)
    
    BARTImageSize* imageSize = [self->mImage getImageSize];
    
    //    size_t rows       = imageSize.rows;
    size_t cols       = imageSize.columns;
    size_t slices     = imageSize.slices;
    size_t gridWidth  = self->mGridSize.width;
    size_t gridHeight = self->mGridSize.height;
    
    BOOL flipX = (self->mFlipMask & MASK_X_FLIP) != 0;
    BOOL flipY = (self->mFlipMask & MASK_Y_FLIP) != 0;
    BOOL flipZ = (self->mFlipMask & MASK_Z_FLIP) != 0;
    
    size_t renderImageDataLength =    cols
    * slices 
    * gridWidth
    * gridHeight
    * NUMBER_OF_CHANNELS
    * sizeof(float);
    float* renderImageData = malloc(renderImageDataLength);
    
    float min = [[self->mImageMinMax objectAtIndex:0] floatValue];
    float max = [[self->mImageMinMax objectAtIndex:1] floatValue];
    if (min == max) {
        // Avoid division by 0 later on
        min = 0.0f;
        if (max == 0.0f) max = FLT_MAX;
    }
    float normalized = 0.0f;
    
    size_t srcSliceNr = 0;
    if (   gridWidth == 1
        && gridHeight == 1) {
        // Single slice view
        
        int renderIndex = 0;
        int tarSliceNr = (flipZ) ? (self->mSliceCount - self->mCurrentSlice - 1) : self->mCurrentSlice;
        for (size_t slice = 0; slice < slices; slice++) {
            
            srcSliceNr = (flipY) ? slices - slice - 1 : slice;
            float* sliceData = [self->mImage getSliceData:(uint) srcSliceNr
                                               atTimestep:self->mCurrentTimestep];
            size_t srcCol;
            for (size_t col = 0; col < cols; col++) {
                srcCol = (flipX) ? cols - col - 1 : col;
                normalized = (sliceData[tarSliceNr * cols + srcCol] - min) / (max - min);
                renderImageData[renderIndex++] = normalized;
                renderImageData[renderIndex++] = normalized;
                renderImageData[renderIndex++] = normalized;
                renderImageData[renderIndex++] = self->mAlpha;
            }
            
            free(sliceData);
        }
        
    } else {
        // Many slice view
        // TODO: much space for parallelization here
        
        size_t renderIndex = 0;
        size_t flippedGridIndex;
        NSUInteger relevantSlicesCount = [self->mRelevantSlices count];
        for (int slice = 0; slice < slices; slice++) {
            srcSliceNr = (flipY) ? slices - slice - 1 : slice;
            float* sliceData = [self->mImage getSliceData:(uint) srcSliceNr
                                               atTimestep:self->mCurrentTimestep];
            
            size_t srcCol;
            for (size_t col = 0; col < cols; col++) {
                srcCol = (flipX) ? cols - col - 1 : col;
                
                for (int gridIndex = 0; gridIndex < gridWidth * gridHeight; gridIndex++) {
                    if (gridIndex < relevantSlicesCount) {
                        flippedGridIndex = (flipZ) ? relevantSlicesCount - gridIndex - 1 : gridIndex;
                        size_t relevantRow = [[self->mRelevantSlices objectAtIndex:flippedGridIndex] intValue];
                        normalized = (sliceData[relevantRow * cols + srcCol] - min) / (max - min);
                    } else {
                        normalized = 0.0f;
                    }
                    
                    renderIndex = ((gridIndex / gridWidth) * gridWidth * slices * cols + (gridIndex % gridWidth) * cols + (slice * gridWidth * cols + col)) * NUMBER_OF_CHANNELS;
                    renderImageData[renderIndex++] = normalized;
                    renderImageData[renderIndex++] = normalized;
                    renderImageData[renderIndex++] = normalized;
                    renderImageData[renderIndex]   = self->mAlpha;
                }
            }
            
            free(sliceData);
        }
    }
    
    CIImage* ciImage = [self imageFromFloat:renderImageData 
                                     length:renderImageDataLength 
                                bytesPerRow:gridWidth * cols * NUMBER_OF_CHANNELS * sizeof(float)
                                      width:gridWidth * cols 
                                     height:gridHeight * slices];
    free(renderImageData);
    
    return ciImage;
}

-(CIImage*)renderTurnLeftRotateRightImage
{
    // TODO: too much c&p from renderIdenticalImage ;)
    
    BARTImageSize* imageSize = [self->mImage getImageSize];
    
    size_t rows       = imageSize.rows;
    size_t cols       = imageSize.columns;
    size_t slices     = imageSize.slices;
    size_t gridWidth  = self->mGridSize.width;
    size_t gridHeight = self->mGridSize.height;
    
    BOOL flipX = (self->mFlipMask & MASK_X_FLIP) != 0;
    BOOL flipY = (self->mFlipMask & MASK_Y_FLIP) != 0;
    BOOL flipZ = (self->mFlipMask & MASK_Z_FLIP) != 0;
    
    size_t renderImageDataLength =    rows
                                    * slices 
                                    * gridWidth
                                    * gridHeight
                                    * NUMBER_OF_CHANNELS
                                    * sizeof(float);
    float* renderImageData = malloc(renderImageDataLength);
    
    float min = [[self->mImageMinMax objectAtIndex:0] floatValue];
    float max = [[self->mImageMinMax objectAtIndex:1] floatValue];
    if (min == max) {
        // Avoid division by 0 later on
        min = 0.0f;
        if (max == 0.0f) max = FLT_MAX;
    }
    float normalized = 0.0f;
    
    size_t srcSliceNr;
    if (   gridWidth == 1
        && gridHeight == 1) {
        // Single slice view
        int renderIndex = 0;
        for (size_t slice = 0; slice < slices; slice++) {
            srcSliceNr = (flipY) ? slices - slice - 1 : slice;
            float* sliceData = [self->mImage getSliceData:(uint) srcSliceNr
                                               atTimestep:self->mCurrentTimestep];
            
            int tarSliceNr = (flipZ) ? self->mSliceCount - self->mCurrentSlice - 1 : self->mCurrentSlice;
            size_t srcRow;
            for (size_t row = 0; row < rows; row++) {
                srcRow = (flipX) ? rows - row - 1 : row;
                normalized = (sliceData[srcRow * cols + tarSliceNr] - min) / (max - min);
                renderImageData[renderIndex++] = normalized;
                renderImageData[renderIndex++] = normalized;
                renderImageData[renderIndex++] = normalized;
                renderImageData[renderIndex++] = self->mAlpha;
            }
            
            free(sliceData);
        }
        
    } else {
        // Many slice view
        // TODO: much space for parallelization here
        
        size_t renderIndex = 0;
        NSUInteger relevantSlicesCount = [self->mRelevantSlices count];
        for (int slice = 0; slice < slices; slice++) {
            srcSliceNr = (flipY) ? slices - slice - 1 : slice;
            float* sliceData = [self->mImage getSliceData:(uint) srcSliceNr
                                               atTimestep:self->mCurrentTimestep];
            
            size_t srcRow;
            for (size_t row = 0; row < rows; row++) {
                // the column number in the target (sagittal) image equals the row number in the source (axial) data
                srcRow = (flipX) ? rows - row - 1 : row;
                
                size_t flippedGridIndex;
                for (int gridIndex = 0; gridIndex < gridWidth * gridHeight; gridIndex++) {
                    // gridIndex equals one column of data in the original axial slice data
                    
                    if (gridIndex < relevantSlicesCount) {
                        flippedGridIndex = (flipZ) ? relevantSlicesCount - gridIndex - 1 : gridIndex;
                        size_t relevantCol = [[self->mRelevantSlices objectAtIndex:flippedGridIndex] intValue];
                        normalized = (sliceData[srcRow * cols + relevantCol] - min) / (max - min);
                    } else {
                        normalized = 0.0f;
                    }
                    // ((gridRow * gridWidth * cols * rows) + gridCol * cols)
                    renderIndex = ((gridIndex / gridWidth) * gridWidth * rows * slices 
                                   + (gridIndex % gridWidth) * rows 
                                   + (slice * gridWidth * rows + row)
                                   ) * NUMBER_OF_CHANNELS;
                    renderImageData[renderIndex++] = normalized;
                    renderImageData[renderIndex++] = normalized;
                    renderImageData[renderIndex++] = normalized;
                    renderImageData[renderIndex]   = self->mAlpha;
                }
            }
            
            free(sliceData);
        }
    }
    
    CIImage* ciImage = [self imageFromFloat:renderImageData 
                                     length:renderImageDataLength 
                                bytesPerRow:gridWidth * rows * NUMBER_OF_CHANNELS * sizeof(float)
                                      width:gridWidth * rows
                                     height:gridHeight * slices];
    free(renderImageData);
    
    return ciImage;
}

-(CIImage*)renderTurnLeftImage
{
    // TODO: too much c&p from renderIdenticalImage ;)
    
    BARTImageSize* imageSize = [self->mImage getImageSize];
    
    size_t rows       = imageSize.rows;
    size_t cols       = imageSize.columns;
    size_t slices     = imageSize.slices;
    size_t gridWidth  = self->mGridSize.width;
    size_t gridHeight = self->mGridSize.height;
    
    BOOL flipX = (self->mFlipMask & MASK_X_FLIP) != 0;
    BOOL flipY = (self->mFlipMask & MASK_Y_FLIP) != 0;
    BOOL flipZ = (self->mFlipMask & MASK_Z_FLIP) != 0;
    
    size_t renderImageDataLength =    slices
    * rows 
    * gridWidth
    * gridHeight
    * NUMBER_OF_CHANNELS
    * sizeof(float);
    float* renderImageData = malloc(renderImageDataLength);
    
    float min = [[self->mImageMinMax objectAtIndex:0] floatValue];
    float max = [[self->mImageMinMax objectAtIndex:1] floatValue];
    if (min == max) {
        // Avoid division by 0 later on
        min = 0.0f;
        if (max == 0.0f) max = FLT_MAX;
    }
    float normalized = 0.0f;
    
    size_t srcSliceNr;
    size_t srcRow;
    if (   gridWidth == 1
        && gridHeight == 1) {
        // Single slice view
        
        size_t renderIndex = 0;
        int tarSliceNr = (flipZ) ? (self->mSliceCount - self->mCurrentSlice - 1) : self->mCurrentSlice;
        for (int slice = 0; slice < slices; slice++) {
            
            srcSliceNr = (flipX) ? slices - slice - 1 : slice;
            float* sliceData = [self->mImage getSliceData:(uint) srcSliceNr
                                               atTimestep:self->mCurrentTimestep];
            
            for (int row = 0; row < rows; row++) {
                srcRow = (flipY) ? rows - row - 1 : row;
                normalized  = (sliceData[srcRow * cols + tarSliceNr] - min) / (max - min);
                renderIndex = (row * slices + slice) * NUMBER_OF_CHANNELS;
                renderImageData[renderIndex++] = normalized;
                renderImageData[renderIndex++] = normalized;
                renderImageData[renderIndex++] = normalized;
                renderImageData[renderIndex] = self->mAlpha;
            }
            
            free(sliceData);
        }
        
    } else {
        // Many slice view
        // TODO: much space for parallelization here
        
        size_t renderIndex = 0;
        NSUInteger relevantSlicesCount = [self->mRelevantSlices count];
        size_t flippedGridIndex;
        for (int slice = 0; slice < slices; slice++) {
            srcSliceNr = (flipX) ? slices - slice - 1 : slice;
            float* sliceData = [self->mImage getSliceData:(uint) srcSliceNr
                                               atTimestep:self->mCurrentTimestep];
            
            for (int gridIndex = 0; gridIndex < gridWidth * gridHeight; gridIndex++) {
                if (gridIndex < relevantSlicesCount) {
                    flippedGridIndex = (flipZ) ? relevantSlicesCount - gridIndex - 1 : gridIndex;
                    size_t relevantCol = [[self->mRelevantSlices objectAtIndex:flippedGridIndex] intValue];
                    
                    for (int row = 0; row < rows; row++) {
                        srcRow = (flipY) ? rows - row - 1 : row;
                        normalized = (sliceData[srcRow * cols + relevantCol] - min) / (max - min);
                        renderIndex = ((gridIndex / gridWidth) * gridWidth * slices * rows // Grid row
                                       + (gridIndex % gridWidth) * slices                  // Grid col
                                       + (row * gridWidth * slices + slice)                // Position in grid tile
                                       ) * NUMBER_OF_CHANNELS;
                        renderImageData[renderIndex++] = normalized;
                        renderImageData[renderIndex++] = normalized;
                        renderImageData[renderIndex++] = normalized;
                        renderImageData[renderIndex]   = self->mAlpha;
                    }
                }
            }
            
            free(sliceData);
        }
    }
    
    CIImage* ciImage = [self imageFromFloat:renderImageData 
                                     length:renderImageDataLength 
                                bytesPerRow:gridWidth * slices * NUMBER_OF_CHANNELS * sizeof(float)
                                      width:gridWidth * slices 
                                     height:gridHeight * rows];
    free(renderImageData);
    
    return ciImage;
}

-(CIImage*)renderTurnUpRotateRightImage
{
    // TODO: too much c&p from renderIdenticalImage ;)
    
    BARTImageSize* imageSize = [self->mImage getImageSize];
    
    //    size_t rows       = imageSize.rows;
    size_t cols       = imageSize.columns;
    size_t slices     = imageSize.slices;
    size_t gridWidth  = self->mGridSize.width;
    size_t gridHeight = self->mGridSize.height;
    
    BOOL flipX = (self->mFlipMask & MASK_X_FLIP) != 0;
    BOOL flipY = (self->mFlipMask & MASK_Y_FLIP) != 0;
    BOOL flipZ = (self->mFlipMask & MASK_Z_FLIP) != 0;
    
    size_t renderImageDataLength =    slices
                                    * cols
                                    * gridWidth
                                    * gridHeight
                                    * NUMBER_OF_CHANNELS
                                    * sizeof(float);
    float* renderImageData = malloc(renderImageDataLength);
    
    float min = [[self->mImageMinMax objectAtIndex:0] floatValue];
    float max = [[self->mImageMinMax objectAtIndex:1] floatValue];
    if (min == max) {
        // Avoid division by 0 later on
        min = 0.0f;
        if (max == 0.0f) max = FLT_MAX;
    }
    float normalized = 0.0f;
    
    size_t srcSliceNr;
    size_t srcCol;
    if (   gridWidth == 1
        && gridHeight == 1) {
        // Single slice view
        
        size_t renderIndex;
        int tarSliceNr = (flipZ) ? (self->mSliceCount - self->mCurrentSlice - 1) : self->mCurrentSlice;
        for (int slice = 0; slice < slices; slice++) {
            
            srcSliceNr = (flipX) ? slices - slice - 1 : slice;
            float* sliceData = [self->mImage getSliceData:(uint) srcSliceNr
                                               atTimestep:self->mCurrentTimestep];
            
            for (int col = 0; col < cols; col++) {
                srcCol = (flipY) ? cols - col - 1 : col;
                normalized  = (sliceData[tarSliceNr * cols + srcCol] - min) / (max - min);
                renderIndex = (col * slices + slice) * NUMBER_OF_CHANNELS;
                renderImageData[renderIndex++] = normalized;
                renderImageData[renderIndex++] = normalized;
                renderImageData[renderIndex++] = normalized;
                renderImageData[renderIndex] = self->mAlpha;
            }
            
            free(sliceData);
        }
        
    } else {
        // Many slice view
        // TODO: much space for parallelization here
        
        size_t renderIndex = 0;
        NSUInteger relevantSlicesCount = [self->mRelevantSlices count];
        size_t flippedGridIndex;
        for (int slice = 0; slice < slices; slice++) {
            srcSliceNr = (flipX) ? slices - slice - 1 : slice;
            float* sliceData = [self->mImage getSliceData:(uint) srcSliceNr
                                               atTimestep:self->mCurrentTimestep];
            
            for (int gridIndex = 0; gridIndex < gridWidth * gridHeight; gridIndex++) {
                if (gridIndex < relevantSlicesCount) {
                    flippedGridIndex = (flipZ) ? relevantSlicesCount - gridIndex - 1 : gridIndex;
                    size_t relevantRow = [[self->mRelevantSlices objectAtIndex:flippedGridIndex] intValue];
                    
                    for (int col = 0; col < cols; col++) {
                        srcCol = (flipY) ? cols - col - 1: col; 
                        normalized = (sliceData[relevantRow * cols + srcCol] - min) / (max - min);
                        renderIndex = ((gridIndex / gridWidth) * gridWidth * slices * cols // Grid row
                                       + (gridIndex % gridWidth) * slices                  // Grid col
                                       + (col * gridWidth * slices + slice)                // Position in grid tile
                                       ) * NUMBER_OF_CHANNELS;
                        renderImageData[renderIndex++] = normalized;
                        renderImageData[renderIndex++] = normalized;
                        renderImageData[renderIndex++] = normalized;
                        renderImageData[renderIndex]   = self->mAlpha;
                    }
                }
            }
            
            free(sliceData);
        }
    }
    
    CIImage* ciImage = [self imageFromFloat:renderImageData 
                                     length:renderImageDataLength 
                                bytesPerRow:gridWidth * slices * NUMBER_OF_CHANNELS * sizeof(float)
                                      width:gridWidth * slices 
                                     height:gridHeight * cols];
    free(renderImageData);
    
    return ciImage;
}

-(CIImage*)imageFromFloat:(float*)data 
                   length:(size_t)len 
              bytesPerRow:(size_t)bpr
                    width:(size_t)w
                   height:(size_t)h
{
    NSSize ciImageSize;
    ciImageSize.width  = w;
    ciImageSize.height = h;
//    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CIImage* ciImage = [[CIImage alloc] initWithBitmapData:[NSData dataWithBytes:data
                                                                          length:len]
                                               bytesPerRow:bpr
                                                      size:ciImageSize 
                                                    format:kCIFormatRGBAf
                                                colorSpace:nil]; //colorSpace];
//    CGColorSpaceRelease(colorSpace);
    
    return ciImage;
}

-(NSImage*)ciImageToNSImage:(CIImage*)ciImage
{
    NSSize ciImageSize = [ciImage extent].size;
    NSBitmapImageRep* imageRep = [[[NSBitmapImageRep alloc] initWithCIImage:ciImage] autorelease];
    CGImageRef        cgImage = imageRep.CGImage;
    
    NSImage*          nsImage = [[[NSImage alloc] initWithCGImage:cgImage 
                                                             size:ciImageSize] autorelease];
    
    return nsImage;
}

-(NSImage*)fixSizeOf:(NSImage*)image 
                with:(BARTImageSize*)dataSize
{
    if (image == nil) {
        return nil;
    }
    
    NSSize correctedDataSize;
    float voxGapX = 0.0f;
    float voxGapY = 0.0f;
    float voxSizeX = 1.0f;
    float voxSizeY = 1.0f;
    
    BOOL isMainAxial    = self->mMainOrientation == ORIENT_AXIAL    || self->mMainOrientation == ORIENT_REVAXIAL;
    BOOL isMainCoronal  = self->mMainOrientation == ORIENT_CORONAL  || self->mMainOrientation == ORIENT_REVCORONAL;
    BOOL isMainSagittal = self->mMainOrientation == ORIENT_SAGITTAL || self->mMainOrientation == ORIENT_REVSAGITTAL;
    // Find the above parameters depending on image data orientation (mMainOrientation)
    //                                  and view display orientation (mViewOrientation)
    // TODO: reduce to actual 6 non-redundant cases!
    if (isMainAxial) {
        switch (self->mTargetOrientation) {
            case ORIENT_AXIAL:
                correctedDataSize.width  = dataSize.columns;
                correctedDataSize.height = dataSize.rows;
                voxGapX  = [[self->mVoxelGap  objectAtIndex:0] floatValue];
                voxGapY  = [[self->mVoxelGap  objectAtIndex:1] floatValue];
                voxSizeX = [[self->mVoxelSize objectAtIndex:0] floatValue]; 
                voxSizeY = [[self->mVoxelSize objectAtIndex:1] floatValue];
                break;
            case ORIENT_CORONAL:
                correctedDataSize.width  = dataSize.columns;
                correctedDataSize.height = dataSize.slices;
                voxGapX  = [[self->mVoxelGap  objectAtIndex:0] floatValue];
                voxGapY  = [[self->mVoxelGap  objectAtIndex:2] floatValue];
                voxSizeX = [[self->mVoxelSize objectAtIndex:0] floatValue]; 
                voxSizeY = [[self->mVoxelSize objectAtIndex:2] floatValue];
                break;
            default:
                correctedDataSize.width  = dataSize.rows;
                correctedDataSize.height = dataSize.slices;
                voxGapX  = [[self->mVoxelGap  objectAtIndex:1] floatValue];
                voxGapY  = [[self->mVoxelGap  objectAtIndex:2] floatValue];
                voxSizeX = [[self->mVoxelSize objectAtIndex:1] floatValue]; 
                voxSizeY = [[self->mVoxelSize objectAtIndex:2] floatValue];
                break;
        }
    } else if (isMainCoronal) {
        switch (self->mTargetOrientation) {
            case ORIENT_AXIAL:
                correctedDataSize.width  = dataSize.columns;
                correctedDataSize.height = dataSize.slices;
                voxGapX  = [[self->mVoxelGap  objectAtIndex:0] floatValue];
                voxGapY  = [[self->mVoxelGap  objectAtIndex:2] floatValue];
                voxSizeX = [[self->mVoxelSize objectAtIndex:0] floatValue]; 
                voxSizeY = [[self->mVoxelSize objectAtIndex:2] floatValue];
                break;
            case ORIENT_CORONAL:
                correctedDataSize.width  = dataSize.columns;
                correctedDataSize.height = dataSize.rows;
                voxGapX  = [[self->mVoxelGap  objectAtIndex:0] floatValue];
                voxGapY  = [[self->mVoxelGap  objectAtIndex:1] floatValue];
                voxSizeX = [[self->mVoxelSize objectAtIndex:0] floatValue]; 
                voxSizeY = [[self->mVoxelSize objectAtIndex:1] floatValue];
                break;
            default:
                correctedDataSize.width  = dataSize.slices;
                correctedDataSize.height = dataSize.rows;
                voxGapX  = [[self->mVoxelGap  objectAtIndex:2] floatValue];
                voxGapY  = [[self->mVoxelGap  objectAtIndex:1] floatValue];
                voxSizeX = [[self->mVoxelSize objectAtIndex:2] floatValue]; 
                voxSizeY = [[self->mVoxelSize objectAtIndex:1] floatValue];
                break;
        }
    } else if (isMainSagittal) {
        switch (self->mTargetOrientation) {
            case ORIENT_AXIAL:
                correctedDataSize.width  = dataSize.slices;
                correctedDataSize.height = dataSize.columns;
                voxGapX  = [[self->mVoxelGap  objectAtIndex:2] floatValue];
                voxGapY  = [[self->mVoxelGap  objectAtIndex:0] floatValue];
                voxSizeX = [[self->mVoxelSize objectAtIndex:2] floatValue]; 
                voxSizeY = [[self->mVoxelSize objectAtIndex:0] floatValue];
                break;
            case ORIENT_CORONAL:
                correctedDataSize.width  = dataSize.slices;
                correctedDataSize.height = dataSize.rows;
                voxGapX  = [[self->mVoxelGap  objectAtIndex:2] floatValue];
                voxGapY  = [[self->mVoxelGap  objectAtIndex:1] floatValue];
                voxSizeX = [[self->mVoxelSize objectAtIndex:2] floatValue]; 
                voxSizeY = [[self->mVoxelSize objectAtIndex:1] floatValue];
                break;
            default:
                correctedDataSize.width  = dataSize.columns;
                correctedDataSize.height = dataSize.rows;
                voxGapX  = [[self->mVoxelGap  objectAtIndex:0] floatValue];
                voxGapY  = [[self->mVoxelGap  objectAtIndex:1] floatValue];
                voxSizeX = [[self->mVoxelSize objectAtIndex:0] floatValue]; 
                voxSizeY = [[self->mVoxelSize objectAtIndex:1] floatValue];
                break;
        }
    }
    
    assert(correctedDataSize.width  > 0);
    assert(correctedDataSize.height > 0);
    
    // Compute real size
    correctedDataSize.width  = (correctedDataSize.width  * voxSizeX + (correctedDataSize.width  - 1) * voxGapX) * self->mGridSize.width;
    correctedDataSize.height = (correctedDataSize.height * voxSizeY + (correctedDataSize.height - 1) * voxGapY) * self->mGridSize.height;
    
    NSSize imageSize = [image size];
    float scale = fmin( imageSize.width  / correctedDataSize.width
                       , imageSize.height / correctedDataSize.height);
    
    //    NSLog(@"ImageSize: (%3.2f, %3.2f)", imageSize.width, imageSize.height);
    //    NSLog(@"CorrectedDataSize after  (%3.2f, %3.2f)", correctedDataSize.width, correctedDataSize.height);
    
    // Hack to enable scaling down of the NSImage in the ImageView
    [image setScalesWhenResized:YES];
    NSSize minSize;
    minSize.width  = correctedDataSize.width  * scale * MIN_SCALE_FACTOR;
    minSize.height = correctedDataSize.height * scale * MIN_SCALE_FACTOR;
    [image setSize:minSize];
    
    return image;
}


-(BADataVoxel*)pointToVoxel:(NSPoint)p
{
    NSUInteger x = 0;
    NSUInteger y = 0;
    NSUInteger slice = 0;
    NSUInteger ts = 0;
    
    size_t gridWidth  = self->mGridSize.width;
    size_t gridHeight = self->mGridSize.height;
    
    if (self->mImage != nil
        && p.x >= 0.0f && p.x < self->mColumnCount * gridWidth
        && p.y >= 0.0f && p.y < self->mRowCount    * gridHeight) {
        
        NSUInteger px = p.x;
        NSUInteger py = p.y;
        
        BARTImageSize* imageSize = [self->mImage getImageSize];
        size_t cols = imageSize.columns;
        size_t rows = imageSize.rows;
        size_t slices = imageSize.slices;
    
        BOOL flippedX = (self->mFlipMask & MASK_X_FLIP) != 0;
        BOOL flippedY = (self->mFlipMask & MASK_Y_FLIP) != 0;
        BOOL flippedZ = (self->mFlipMask & MASK_Z_FLIP) != 0;
        
        size_t tarSlice;
        
        if (   gridWidth == 1
            && gridHeight == 1) {
            tarSlice = self->mCurrentSlice;
            
        } else {
            size_t gridIndex = (py / self->mRowCount) * gridWidth + px / self->mColumnCount;
            NSUInteger relevantSlicesCount = [self->mRelevantSlices count];
            // Need to flip target slice here already.
            gridIndex = (flippedZ) ? relevantSlicesCount - gridIndex - 1 : gridIndex;
            tarSlice = [[self->mRelevantSlices objectAtIndex:gridIndex] intValue];
            
            px = px % self->mColumnCount;
            py = py % self->mRowCount;
        }
        
        // Find source coordinates based on the image (its main orientation), the target orientation
        // and point p (target coordinates)
        enum ImageDimension* dims = [self->mRelevantSliceFilter getDimensionsFrom:self->mImage
                                                                        alignedTo:self->mTargetOrientation];
        switch (dims[0]) {
            case DIM_WIDTH:
                x = (flippedX) ? cols - px - 1 : px;
                break;
            case DIM_HEIGHT:
                y = (flippedX) ? rows - px - 1 : px;
                break;
            default:
                slice = (flippedX) ? slices - px - 1 : px;
                break;
        }
        switch (dims[1]) {
            case DIM_WIDTH:
                x = (flippedY) ? cols - py - 1 : py;
                break;
            case DIM_HEIGHT:
                y = (flippedY) ? rows - py - 1 : py;
                break;
            default:
                slice = (flippedY) ? slices - py - 1 : py;
                break;
        }
        switch (dims[2]) {
            // Only applying flips for single slice view here. Slice flips for grid view were applied earlier already. 
            case DIM_WIDTH:
                x     = (flippedZ && gridWidth == 1 && gridHeight == 1) ? cols - tarSlice - 1   : tarSlice;
                break;
            case DIM_HEIGHT:
                y     = (flippedZ && gridWidth == 1 && gridHeight == 1) ? rows - tarSlice - 1   : tarSlice;
                break;
            default:
                slice = (flippedZ && gridWidth == 1 && gridHeight == 1) ? slices - tarSlice - 1 : tarSlice;
                break;
        }
        free(dims);
        
        ts = self->mCurrentTimestep;
    }
    
    BADataVoxel* ret = [[[BADataVoxel alloc] initWithColumn:x
                                                       row:y
                                                     slice:slice
                                                  timestep:ts] autorelease];
    return ret;
}

-(NSString*)description {
    return [NSString stringWithFormat: @"BADataElementRenderer(img=%@, mainOrient=%d, tarOrient=%d, cols=%d, rows=%d, slice=%d/%d, ts=%d/%zd)", self->mImage, self->mMainOrientation, self->mTargetOrientation, self->mColumnCount, self->mRowCount, self->mCurrentSlice, self->mSliceCount, self->mCurrentTimestep, self->mTimestepCount];
}

@end

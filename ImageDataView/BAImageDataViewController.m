//
//  BAImageData.m
//  ImageDataView
//
//  Created by Oliver Zscheyge on 6/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BAImageDataViewController.h"

#import "BAImageSliceSelector.h"

#include <math.h>



static const int   NUMBER_OF_CHANNELS = 4;
static const float MAX_ALPHA = 1.0f;

static const float MIN_SCALE_FACTOR = 0.1f;

static const CGFloat DEFAULT_GRID_SIZE = 1.0f;
static const CGFloat GRID_SIZE_SIX = 6.0f;

static NSString* PROP_VOXELGAP  = @"voxelgap";
static NSString* PROP_VOXELSIZE = @"voxelsize";

static NSString* PROP_COLUMNVEC = @"columnvec";
static NSString* PROP_ROWVEC    = @"rowvec";



@interface BAImageDataViewController (__privateMethods__)

-(void)fetchPropsIfUpdated:(EDDataElement*)image;
-(void)fetchRelevantSlices:(EDDataElement*)image;

-(NSImage*)renderImage;
-(NSImage*)renderIdenticalImage;
-(NSImage*)renderTurnUpImage;
-(NSImage*)renderTurnLeftRotateRightImage;
-(NSImage*)renderTurnLeftImage;
-(NSImage*)renderTurnUpRotateRightImage;

-(NSImage*)fixSizeOf:(NSImage*)image 
                with:(BARTImageSize*)dataSize;

-(void)updateSliceSelectors;
-(void)updateSliceTextField;
-(void)updateSliceSlider;

-(void)updateControlEnabledStates;
-(void)setOrientationAndGridSizeSelectorStates:(BOOL)enabled;
-(void)setSliceSelectorStates:(BOOL)enabled;

@end



@implementation BAImageDataViewController

@synthesize mImageView;

@synthesize mOrientationSelect;
@synthesize mGridSizeSelect;
@synthesize mSliceSelect;
@synthesize mSliceSelectSlider;

- (id)initWithNibName:(NSString *)nibNameOrNil 
               bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self->mImage       = nil;
        self->mImageMinMax = nil;
        self->mVoxelGap    = nil;
        self->mVoxelSize   = nil;
        self->mColumnVec   = nil;
        self->mRowVec      = nil;
        
        self->mPropList = [NSArray arrayWithObjects: PROP_VOXELGAP
                                                   , PROP_VOXELSIZE
                                                   , PROP_COLUMNVEC
                                                   , PROP_ROWVEC
                                                   , nil];
        
        self->mRelevantSliceFilter = [[BAImageSliceSelector alloc] init];
        self->mRelevantSlices = nil;
        self->mCurrentSlice = 0;
        self->mSliceCount   = 1;
        self->mCurrentTimestep = 0;
        
        self->mViewOrientation = ORIENT_SAGITTAL;
        self->mMainOrientation = ORIENT_UNKNOWN;
        
        self->mGridSize    = (NSSize) {DEFAULT_GRID_SIZE, DEFAULT_GRID_SIZE};
        
        [self.mSliceSelectSlider setMinValue:1];
        
        [self updateControlEnabledStates];
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
    
    if (self->mRelevantSliceFilter != nil) [self->mRelevantSliceFilter release];
    if (self->mRelevantSlices      != nil) [self->mRelevantSlices      release];
    
    [super dealloc];
}

-(IBAction)setOrientation:(id)sender
{
    if (sender == self.mOrientationSelect) {
        NSInteger orientationSelectionIndex = [self.mOrientationSelect selectedSegment];
//        NSLog(@"Selected segment (orientation selector): %li", orientationSelectionIndex);
        
        switch (orientationSelectionIndex) {
            case 1:
                self->mViewOrientation = ORIENT_AXIAL;
                break;
            case 2:
                self->mViewOrientation = ORIENT_CORONAL;
                break;
            default:
                self->mViewOrientation = ORIENT_SAGITTAL;
                break;
        }
        
//        [self.mImageView setImageWithURL:[NSURL URLWithString:@"http://www.cbs.mpg.de/institute/building/mpi3n"]];
        
        [self showImage:self->mImage slice:self->mCurrentSlice atTimestep:self->mCurrentTimestep];
    }
}

-(IBAction)setGridSize:(id)sender
{
    if (sender == self.mGridSizeSelect) {
        long selectedIndex = [self.mGridSizeSelect indexOfSelectedItem];
//        NSLog(@"GridSize changed: %ld", selectedIndex);
        
        if (selectedIndex == 0) {
            self->mGridSize = (NSSize) { DEFAULT_GRID_SIZE
                                       , DEFAULT_GRID_SIZE };
        } else if (selectedIndex == 1) {
            self->mGridSize = (NSSize) { GRID_SIZE_SIX
                                       , GRID_SIZE_SIX };
        }
        
//        NSLog(@"Grid size: %2.0f, %2.0f", self->mGridSize.width, self->mGridSize.height);
        
        [self showImage:self->mImage slice:self->mCurrentSlice atTimestep:self->mCurrentTimestep];
        
//        [self updateControlEnabledStates];
    }
}

-(IBAction)selectSlice:(id)sender
{
    int sliceNr = [sender intValue] - 1;
    if (sliceNr >= 0 && sliceNr < self->mSliceCount) {
        self->mCurrentSlice = sliceNr;
    }
    
    [self showImage:self->mImage slice:self->mCurrentSlice atTimestep:self->mCurrentTimestep];
}

-(void)showImage:(EDDataElement*)image
{
    [self showImage:image slice:0 atTimestep:0];
}

-(void)showImage:(EDDataElement*)image
           slice:(uint)sliceNr
      atTimestep:(uint)tstep
{
    if (self->mImage != nil) {
        [self->mImage release];
    }
    
    if (image == nil) {
        if (self->mImageMinMax != nil) {
            [self->mImageMinMax release];
            self->mImageMinMax = nil;
        }
        self->mImage = nil;
        [self->mImageView setImage:nil];
        
    } else {
        [self fetchPropsIfUpdated:image];
        
        self->mImage = image;
        [self->mImage retain];
        
        self->mSliceCount = [self->mRelevantSliceFilter getSliceDimensionSize:self->mImage alignedTo:self->mViewOrientation];
        self->mCurrentSlice = (sliceNr < self->mSliceCount) ? sliceNr : 0;
        self->mCurrentTimestep = tstep;
        [self updateSliceSelectors];
        
        BOOL isSingleSliceView = self->mGridSize.width == 1 && self->mGridSize.height == 1;
        if (!isSingleSliceView) {
            [self fetchRelevantSlices:self->mImage];
        }
        
        NSImage* renderedSlices = [self renderImage];
        BARTImageSize* imageSize = [self->mImage getImageSize];
        renderedSlices = [self fixSizeOf:renderedSlices with:imageSize];
        
        [self->mImageView setImage:renderedSlices];
    }
    
    [self updateControlEnabledStates];
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
        switch (self->mViewOrientation) {
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
        switch (self->mViewOrientation) {
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
        switch (self->mViewOrientation) {
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

-(void)fetchPropsIfUpdated:(EDDataElement*)image
{
    if (self->mImage != image) {
        if (self->mImageMinMax != nil) [self->mImageMinMax release];
        self->mImageMinMax = [[image getMinMaxOfDataElement] retain];
        
        self->mMainOrientation = [image getMainOrientation];
        
        NSDictionary* imageProps = [image getProps:self->mPropList];
        
        if (self->mVoxelGap != nil) [self->mVoxelGap release];
        self->mVoxelGap = [[imageProps valueForKey:PROP_VOXELGAP] retain];
        
        if (self->mVoxelSize != nil) [self->mVoxelSize release];
        self->mVoxelSize = [[imageProps valueForKey:PROP_VOXELSIZE] retain];
        
        if (self->mColumnVec != nil) [self->mColumnVec release];
        self->mColumnVec = [[imageProps valueForKey:PROP_COLUMNVEC] retain];
        
        if (self->mRowVec != nil) [self->mRowVec release];
        self->mRowVec = [[imageProps valueForKey:PROP_ROWVEC] retain];

        NSLog(@"MainOrientation %d", self->mMainOrientation);
        NSLog(@"VoxelGap  %@",  self->mVoxelGap);
        NSLog(@"VoxelSize %@",  self->mVoxelSize);
        NSLog(@"ColumnVec  %@", self->mColumnVec);
        NSLog(@"RowVec %@",     self->mRowVec);
    }
}

-(void)fetchRelevantSlices:(EDDataElement*)image
{
    if (self->mRelevantSlices != nil) [self->mRelevantSlices release];
    self->mRelevantSlices = [[self->mRelevantSliceFilter select:self->mGridSize.width * self->mGridSize.height
                                                     slicesFrom:image 
                                                      alignedTo:self->mViewOrientation] retain]; 
}

-(NSImage*)renderImage
{
    NSImage* renderedSlices = nil;
    enum ImageDimension* dims = [self->mRelevantSliceFilter getDimensionsFrom:self->mImage
                                                                    alignedTo:self->mViewOrientation];

    switch (dims[0]) {
            case DIM_SLICE:
                switch (dims[1]) {
                    case DIM_HEIGHT:
                        renderedSlices = [self renderTurnLeftImage];
                        break;
                    default:
                        renderedSlices = [self renderTurnUpRotateRightImage];
                        break;
                }
                break;
            case DIM_HEIGHT:
                if (dims[1] == DIM_SLICE) {
                    renderedSlices = [self renderTurnLeftRotateRightImage];
                }
                break;
            default:
                // DIM_WIDTH
                switch (dims[1]) {
                    case DIM_SLICE:
                        renderedSlices = [self renderTurnUpImage];
                        break;
                    default:
                        renderedSlices = [self renderIdenticalImage];
                        break;
                }
                break;
    }
    
    free(dims);
    
    return renderedSlices;
}

-(NSImage*)renderIdenticalImage
{
    BARTImageSize* imageSize = [self->mImage getImageSize];

    size_t rows       = imageSize.rows;
    size_t cols       = imageSize.columns;
    size_t gridWidth  = self->mGridSize.width;
    size_t gridHeight = self->mGridSize.height;
    
    size_t renderImageDataLength =   cols
                                   * rows 
                                   * gridWidth
                                   * gridHeight
                                   * NUMBER_OF_CHANNELS
                                   * sizeof(float);
    float* renderImageData = malloc(renderImageDataLength);
    
    NSNumber* max    = [self->mImageMinMax objectAtIndex:1];
    float normalized = 0.0f;
    
    if (   gridWidth == 1
        && gridHeight == 1) {
        // Single slice view
        
        float* sliceData = [self->mImage getSliceData:self->mCurrentSlice 
                                           atTimestep:self->mCurrentTimestep];
    
        for (int i = 0; i < rows * cols; i++) {
            normalized = sliceData[i] / [max floatValue];
            renderImageData[i * NUMBER_OF_CHANNELS]     = normalized;
            renderImageData[i * NUMBER_OF_CHANNELS + 1] = normalized;
            renderImageData[i * NUMBER_OF_CHANNELS + 2] = normalized;
            renderImageData[i * NUMBER_OF_CHANNELS + 3] = MAX_ALPHA;
        }
        
        free(sliceData);
    
    } else {
        // Many slice view
        // TODO: much space for parallelization here
        
        NSUInteger sliceIndex = 0;
        for (int gridRow = 0; gridRow < gridHeight; gridRow++) {
            for (int gridCol = 0; gridCol < gridWidth; gridCol++) {
            
                size_t sliceNr   = 0;
                float* sliceData = NULL;
                if (sliceIndex < self->mSliceCount) {
                    sliceNr   = [[self->mRelevantSlices objectAtIndex:sliceIndex++] intValue]; //gridRow * gridWidth + gridCol;
                    sliceData = [self->mImage getSliceData:sliceNr
                                                atTimestep:self->mCurrentTimestep];
                }

                if (sliceData != NULL) {
                
                    size_t sliceOffset = ((gridRow * gridWidth * cols * rows) + gridCol * cols) * NUMBER_OF_CHANNELS;
//                    NSLog(@"SliceNr: %ld, sliceOffset: %ld (rows: %ld, cols: %ld", sliceNr, sliceOffset, rows, cols);
                    
                    for (int row = 0; row < rows; row++) {
                        for (int col = 0; col < cols; col++) {
                            normalized = sliceData[row * cols + col] / [max floatValue];
                            renderImageData[sliceOffset + (row * gridWidth * cols + col) * NUMBER_OF_CHANNELS]     = normalized;
                            renderImageData[sliceOffset + (row * gridWidth * cols + col) * NUMBER_OF_CHANNELS + 1] = normalized;
                            renderImageData[sliceOffset + (row * gridWidth * cols + col) * NUMBER_OF_CHANNELS + 2] = normalized;
                            renderImageData[sliceOffset + (row * gridWidth * cols + col) * NUMBER_OF_CHANNELS + 3] = MAX_ALPHA;
                        }
                        
                    }
                    
                    free(sliceData);
                }
            }
        }
    }
    
    NSSize ciImageSize;
    ciImageSize.width  = gridWidth  * cols;
    ciImageSize.height = gridHeight * rows;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CIImage* ciImage = [[CIImage alloc] initWithBitmapData:[NSData dataWithBytes:renderImageData 
                                                                          length:renderImageDataLength]
                                               bytesPerRow:gridWidth * cols * NUMBER_OF_CHANNELS * sizeof(float)
                                                      size:ciImageSize 
                                                    format:kCIFormatRGBAf 
                                                colorSpace:colorSpace];
    
    NSBitmapImageRep* imageRep = [[[NSBitmapImageRep alloc] initWithCIImage:ciImage] autorelease];
    CGImageRef        cgImage = imageRep.CGImage;
    
    NSImage*          nsImage = [[[NSImage alloc] initWithCGImage:cgImage 
                                                            size:ciImageSize] autorelease];
    
    [ciImage release];
    CGColorSpaceRelease(colorSpace);
    free(renderImageData);
    
    return nsImage;
}

-(NSImage*)renderTurnUpImage
{
    // TODO: too much c&p from renderIdenticalImage ;)
    
    BARTImageSize* imageSize = [self->mImage getImageSize];
    
    size_t rows       = imageSize.rows;
    size_t cols       = imageSize.columns;
    size_t slices     = imageSize.slices;
    size_t gridWidth  = self->mGridSize.width;
    size_t gridHeight = self->mGridSize.height;
    
    size_t renderImageDataLength =    cols
                                    * slices 
                                    * gridWidth
                                    * gridHeight
                                    * NUMBER_OF_CHANNELS
                                    * sizeof(float);
    float* renderImageData = malloc(renderImageDataLength);
    
    NSNumber* max    = [self->mImageMinMax objectAtIndex:1];
    float normalized = 0.0f;
    
    if (   gridWidth == 1
        && gridHeight == 1) {
        // Single slice view
        
        int renderIndex = 0;
        for (int slice = 0; slice < slices; slice++) {
            float* sliceData = [self->mImage getSliceData:slice
                                               atTimestep:self->mCurrentTimestep];
            for (int i = 0; i < cols; i++) {
                normalized = sliceData[self->mCurrentSlice * cols + i] / [max floatValue];
                renderImageData[renderIndex++] = normalized;
                renderImageData[renderIndex++] = normalized;
                renderImageData[renderIndex++] = normalized;
                renderImageData[renderIndex++] = MAX_ALPHA;
            }
            
            free(sliceData);
        }
        
    } else {
        // Many slice view
        // TODO: much space for parallelization here
        
        int renderIndex = 0;
        for (int slice = 0; slice < slices; slice++) {
            float* sliceData = [self->mImage getSliceData:slice
                                               atTimestep:self->mCurrentTimestep];
            
            for (int col = 0; col < cols; col++) {
                for (int gridIndex = 0; gridIndex < gridWidth * gridHeight; gridIndex++) {
                    
                    size_t relevantRow = [[self->mRelevantSlices objectAtIndex:gridIndex] intValue];
                    if (relevantRow < rows) {
                        normalized = sliceData[relevantRow * cols + col] / [max floatValue];
                    } else {
                        normalized = 0.0f;
                    }
                    
                    renderIndex = ((gridIndex / gridWidth) * gridWidth * slices * cols + (gridIndex % gridWidth) * cols + (slice * gridWidth * cols + col)) * NUMBER_OF_CHANNELS;
                    renderImageData[renderIndex++] = normalized;
                    renderImageData[renderIndex++] = normalized;
                    renderImageData[renderIndex++] = normalized;
                    renderImageData[renderIndex]   = MAX_ALPHA;
                }
            }
            
            free(sliceData);
        }
    }
    
    NSSize ciImageSize;
    ciImageSize.width  = gridWidth  * cols;
    ciImageSize.height = gridHeight * slices;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CIImage* ciImage = [[CIImage alloc] initWithBitmapData:[NSData dataWithBytes:renderImageData 
                                                                          length:renderImageDataLength]
                                               bytesPerRow:gridWidth * cols * NUMBER_OF_CHANNELS * sizeof(float)
                                                      size:ciImageSize 
                                                    format:kCIFormatRGBAf 
                                                colorSpace:colorSpace];
    
    NSBitmapImageRep* imageRep = [[[NSBitmapImageRep alloc] initWithCIImage:ciImage] autorelease];
    CGImageRef        cgImage = imageRep.CGImage;
    
    NSImage*          nsImage = [[[NSImage alloc] initWithCGImage:cgImage 
                                                             size:ciImageSize] autorelease];
    
    [ciImage release];
    CGColorSpaceRelease(colorSpace);
    free(renderImageData);
    
    return nsImage;
}

-(NSImage*)renderTurnLeftRotateRightImage
{
    // TODO: too much c&p from renderIdenticalImage ;)
    
    BARTImageSize* imageSize = [self->mImage getImageSize];
    
    size_t rows       = imageSize.rows;
    size_t cols       = imageSize.columns;
    size_t slices     = imageSize.slices;
    size_t gridWidth  = self->mGridSize.width;
    size_t gridHeight = self->mGridSize.height;
    
    size_t renderImageDataLength =    rows
                                    * slices 
                                    * gridWidth
                                    * gridHeight
                                    * NUMBER_OF_CHANNELS
                                    * sizeof(float);
    float* renderImageData = malloc(renderImageDataLength);
    
    NSNumber* max    = [self->mImageMinMax objectAtIndex:1];
    float normalized = 0.0f;
    
    if (   gridWidth == 1
        && gridHeight == 1) {
        // Single slice view
        
        int renderIndex = 0;
        for (int slice = 0; slice < slices; slice++) {
            float* sliceData = [self->mImage getSliceData:slice
                                               atTimestep:self->mCurrentTimestep];
            for (int i = 0; i < rows; i++) {
                normalized = sliceData[i * cols + self->mCurrentSlice] / [max floatValue];
                renderImageData[renderIndex++] = normalized;
                renderImageData[renderIndex++] = normalized;
                renderImageData[renderIndex++] = normalized;
                renderImageData[renderIndex++] = MAX_ALPHA;
            }
            
            free(sliceData);
        }
        
    } else {
        // Many slice view
        // TODO: much space for parallelization here
        
        int renderIndex = 0;
        for (int slice = 0; slice < slices; slice++) {
            float* sliceData = [self->mImage getSliceData:slice
                                               atTimestep:self->mCurrentTimestep];
            for (int row = 0; row < rows; row++) {
                // the column number in the target (sagittal) image equals the row number in the source (axial) data
                for (int gridIndex = 0; gridIndex < gridWidth * gridHeight; gridIndex++) {
                    // gridIndex equals one column of data in the original axial slice data
                    size_t relevantCol = [[self->mRelevantSlices objectAtIndex:gridIndex] intValue];
                    if (relevantCol < cols) {
                        normalized = sliceData[row * cols + relevantCol] / [max floatValue];
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
                    renderImageData[renderIndex]   = MAX_ALPHA;
                }
            }
            
            free(sliceData);
        }
    }
    
    NSSize ciImageSize;
    ciImageSize.width  = gridWidth  * rows;
    ciImageSize.height = gridHeight * slices;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CIImage* ciImage = [[CIImage alloc] initWithBitmapData:[NSData dataWithBytes:renderImageData 
                                                                          length:renderImageDataLength]
                                               bytesPerRow:gridWidth * rows * NUMBER_OF_CHANNELS * sizeof(float)
                                                      size:ciImageSize 
                                                    format:kCIFormatRGBAf 
                                                colorSpace:colorSpace];
    
    NSBitmapImageRep* imageRep = [[[NSBitmapImageRep alloc] initWithCIImage:ciImage] autorelease];
    CGImageRef        cgImage = imageRep.CGImage;
    
    NSImage*          nsImage = [[[NSImage alloc] initWithCGImage:cgImage 
                                                             size:ciImageSize] autorelease];
    
    [ciImage release];
    CGColorSpaceRelease(colorSpace);
    free(renderImageData);
    
    return nsImage;
}

-(NSImage*)renderTurnLeftImage;
{
    // TODO: too much c&p from renderIdenticalImage ;)
    
    BARTImageSize* imageSize = [self->mImage getImageSize];
    
    size_t rows       = imageSize.rows;
    size_t cols       = imageSize.columns;
    size_t slices     = imageSize.slices;
    size_t gridWidth  = self->mGridSize.width;
    size_t gridHeight = self->mGridSize.height;
    
    size_t renderImageDataLength =    slices
                                    * rows 
                                    * gridWidth
                                    * gridHeight
                                    * NUMBER_OF_CHANNELS
                                    * sizeof(float);
    float* renderImageData = malloc(renderImageDataLength);
    
    NSNumber* max    = [self->mImageMinMax objectAtIndex:1];
    float normalized = 0.0f;
    
    if (   gridWidth == 1
        && gridHeight == 1) {
        // Single slice view
        
        for (int slice = 0; slice < slices; slice++) {
            float* sliceData = [self->mImage getSliceData:slice
                                               atTimestep:self->mCurrentTimestep];
            int renderIndex = 0;
            for (int i = 0; i < rows; i++) {
                normalized  = sliceData[i * cols + self->mCurrentSlice] / [max floatValue];
                renderIndex = (i * slices + slice) * NUMBER_OF_CHANNELS;
                renderImageData[renderIndex++] = normalized;
                renderImageData[renderIndex++] = normalized;
                renderImageData[renderIndex++] = normalized;
                renderImageData[renderIndex] = MAX_ALPHA;
            }
            
            free(sliceData);
        }
        
    } else {
        // Many slice view
        // TODO: much space for parallelization here
        
        int renderIndex = 0;
        for (int slice = 0; slice < slices; slice++) {
            float* sliceData = [self->mImage getSliceData:slice
                                               atTimestep:self->mCurrentTimestep];
                        
            for (int gridIndex = 0; gridIndex < gridWidth * gridHeight; gridIndex++) {
                size_t relevantCol = [[self->mRelevantSlices objectAtIndex:gridIndex] intValue];
                    
                for (int row = 0; row < rows; row++) {
                    if (relevantCol < cols) {
                        normalized = sliceData[row * cols + relevantCol] / [max floatValue];
                    } else {
                        normalized = 0.0f;
                    }
                    
                    renderIndex = ((gridIndex / gridWidth) * gridWidth * slices * rows // Grid row
                                   + (gridIndex % gridWidth) * slices                  // Grid col
                                   + (row * gridWidth * slices + slice)                // Position in grid tile
                                  ) * NUMBER_OF_CHANNELS;
                    renderImageData[renderIndex++] = normalized;
                    renderImageData[renderIndex++] = normalized;
                    renderImageData[renderIndex++] = normalized;
                    renderImageData[renderIndex]   = MAX_ALPHA;
                }
            }
            
            free(sliceData);
        }
    }
    
    NSSize ciImageSize;
    ciImageSize.width  = gridWidth  * slices;
    ciImageSize.height = gridHeight * rows;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CIImage* ciImage = [[CIImage alloc] initWithBitmapData:[NSData dataWithBytes:renderImageData 
                                                                          length:renderImageDataLength]
                                               bytesPerRow:gridWidth * slices * NUMBER_OF_CHANNELS * sizeof(float)
                                                      size:ciImageSize 
                                                    format:kCIFormatRGBAf 
                                                colorSpace:colorSpace];
    
    NSBitmapImageRep* imageRep = [[[NSBitmapImageRep alloc] initWithCIImage:ciImage] autorelease];
    CGImageRef        cgImage = imageRep.CGImage;
    
    NSImage*          nsImage = [[[NSImage alloc] initWithCGImage:cgImage 
                                                             size:ciImageSize] autorelease];
    
    [ciImage release];
    CGColorSpaceRelease(colorSpace);
    free(renderImageData);
    
    return nsImage;
}

-(NSImage*)renderTurnUpRotateRightImage
{
    // TODO: too much c&p from renderIdenticalImage ;)
    
    BARTImageSize* imageSize = [self->mImage getImageSize];
    
    size_t rows       = imageSize.rows;
    size_t cols       = imageSize.columns;
    size_t slices     = imageSize.slices;
    size_t gridWidth  = self->mGridSize.width;
    size_t gridHeight = self->mGridSize.height;
    
    size_t renderImageDataLength =    slices
                                    * cols
                                    * gridWidth
                                    * gridHeight
                                    * NUMBER_OF_CHANNELS
                                    * sizeof(float);
    float* renderImageData = malloc(renderImageDataLength);
    
    NSNumber* max    = [self->mImageMinMax objectAtIndex:1];
    float normalized = 0.0f;
    
    if (   gridWidth == 1
        && gridHeight == 1) {
        // Single slice view
        
        for (int slice = 0; slice < slices; slice++) {
            float* sliceData = [self->mImage getSliceData:slice
                                               atTimestep:self->mCurrentTimestep];
            int renderIndex = 0;
            for (int col = 0; col < cols; col++) {
                normalized  = sliceData[self->mCurrentSlice * cols + col] / [max floatValue];
                renderIndex = (col * slices + slice) * NUMBER_OF_CHANNELS;
                renderImageData[renderIndex++] = normalized;
                renderImageData[renderIndex++] = normalized;
                renderImageData[renderIndex++] = normalized;
                renderImageData[renderIndex] = MAX_ALPHA;
            }
            
            free(sliceData);
        }
        
    } else {
        // Many slice view
        // TODO: much space for parallelization here
        
        int renderIndex = 0;
        for (int slice = 0; slice < slices; slice++) {
            float* sliceData = [self->mImage getSliceData:slice
                                               atTimestep:self->mCurrentTimestep];
            
            for (int gridIndex = 0; gridIndex < gridWidth * gridHeight; gridIndex++) {
                size_t relevantCol = [[self->mRelevantSlices objectAtIndex:gridIndex] intValue];
                
                for (int row = 0; row < rows; row++) {
                    if (relevantCol < cols) {
                        normalized = sliceData[row * cols + relevantCol] / [max floatValue];
                    } else {
                        normalized = 0.0f;
                    }
                    
                    renderIndex = ((gridIndex / gridWidth) * gridWidth * slices * rows // Grid row
                                   + (gridIndex % gridWidth) * slices                  // Grid col
                                   + (row * gridWidth * slices + slice)                // Position in grid tile
                                   ) * NUMBER_OF_CHANNELS;
                    renderImageData[renderIndex++] = normalized;
                    renderImageData[renderIndex++] = normalized;
                    renderImageData[renderIndex++] = normalized;
                    renderImageData[renderIndex]   = MAX_ALPHA;
                }
            }
            
            free(sliceData);
        }
    }
    
    NSSize ciImageSize;
    ciImageSize.width  = gridWidth  * slices;
    ciImageSize.height = gridHeight * cols;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CIImage* ciImage = [[CIImage alloc] initWithBitmapData:[NSData dataWithBytes:renderImageData 
                                                                          length:renderImageDataLength]
                                               bytesPerRow:gridWidth * slices * NUMBER_OF_CHANNELS * sizeof(float)
                                                      size:ciImageSize 
                                                    format:kCIFormatRGBAf 
                                                colorSpace:colorSpace];
    
    NSBitmapImageRep* imageRep = [[[NSBitmapImageRep alloc] initWithCIImage:ciImage] autorelease];
    CGImageRef        cgImage = imageRep.CGImage;
    
    NSImage*          nsImage = [[[NSImage alloc] initWithCGImage:cgImage 
                                                             size:ciImageSize] autorelease];
    
    [ciImage release];
    CGColorSpaceRelease(colorSpace);
    free(renderImageData);
    
    return nsImage;
}

-(void)updateSliceSelectors
{
    [self updateSliceTextField];
    [self updateSliceSlider];
}

-(void)updateSliceTextField
{
    [self.mSliceSelect setStringValue:[NSString stringWithFormat:@"%d/%ld", 
                                       (self->mCurrentSlice + 1),           // Display natural indices starting with 1
                                       self->mSliceCount]];
}

-(void)updateSliceSlider
{
    [self.mSliceSelectSlider setIntValue:(self->mCurrentSlice + 1)];        // Same thing with the slider
    [self.mSliceSelectSlider setMaxValue:self->mSliceCount];
}

-(void)updateControlEnabledStates
{
    if (self->mImage == nil) {
        // Deactivate all controls
        [self setOrientationAndGridSizeSelectorStates:NO];
        [self setSliceSelectorStates:NO];
        
    } else {
        // Activate orientation selection, slice grid selection
        [self setOrientationAndGridSizeSelectorStates:YES];
        
        if (   self->mGridSize.width  == DEFAULT_GRID_SIZE 
            && self->mGridSize.height == DEFAULT_GRID_SIZE) {
            [self setSliceSelectorStates:YES];
        } else {
            [self setSliceSelectorStates:NO];
        }
    }
}

-(void)setOrientationAndGridSizeSelectorStates:(BOOL)enabled
{
    [self.mOrientationSelect setEnabled:enabled];
    [self.mGridSizeSelect setEnabled:enabled];
}

-(void)setSliceSelectorStates:(BOOL)enabled
{
    [self.mSliceSelect setEnabled:enabled];
    [self.mSliceSelectSlider setEnabled:enabled];
}

@end

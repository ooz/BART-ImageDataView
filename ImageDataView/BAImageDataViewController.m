//
//  BAImageData.m
//  ImageDataView
//
//  Created by Oliver Zscheyge on 6/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BAImageDataViewController.h"



static const int   NUMBER_OF_CHANNELS = 4;
static const float MAX_ALPHA = 1.0f;

static const CGFloat DEFAULT_GRID_SIZE = 1.0f;
static const CGFloat GRID_SIZE_SIX = 5.0f;

static NSString* PROP_VOXELGAP  = @"voxelgap";
static NSString* PROP_VOXELSIZE = @"voxelsize";

static NSString* PROP_COLUMNVEC = @"columnvec";
static NSString* PROP_ROWVEC    = @"rowvec";



@interface BAImageDataViewController (__privateMethods__)

-(void)fetchPropsIfUpdated:(EDDataElement*)image;

-(NSImage*)renderSagittalImage;
-(NSImage*)renderAxialImage;
-(NSImage*)renderCoronarImage;

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
        
        self->mCurrentSlice = 0;
        self->mSliceCount   = 1;
        self->mCurrentTimestep = 0;
        
        self->mOrientation = ORIENT_SAGITTAL;
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
    
    [super dealloc];
}

-(IBAction)setOrientation:(id)sender
{
    if (sender == self.mOrientationSelect) {
        NSInteger orientationSelectionIndex = [self.mOrientationSelect selectedSegment];
//        NSLog(@"Selected segment (orientation selector): %li", orientationSelectionIndex);
        
        switch (orientationSelectionIndex) {
            case 1:
                self->mOrientation = ORIENT_AXIAL;
                break;
            case 2:
                self->mOrientation = ORIENT_CORONAL;
                break;
            default:
                self->mOrientation = ORIENT_SAGITTAL;
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
        
        BARTImageSize* imageSize = [self->mImage getImageSize];
        
        switch (self->mOrientation) {
            case ORIENT_AXIAL:
                self->mSliceCount      = imageSize.slices;
                self->mCurrentSlice    = sliceNr;
                break;
            case ORIENT_CORONAL:
                self->mSliceCount = imageSize.rows;
                self->mCurrentSlice = (sliceNr < imageSize.rows) ? sliceNr : 0;
                break;
            default:
                self->mSliceCount = imageSize.columns;
                self->mCurrentSlice = (sliceNr < imageSize.columns) ? sliceNr : 0;
                break;
        }
        
        
        self->mCurrentTimestep = tstep;
        [self updateSliceSelectors];
        
        
        NSImage* renderedSlices = nil;
        switch (self->mOrientation) {
            case ORIENT_AXIAL:
                renderedSlices = [self renderAxialImage];
                break;
            case ORIENT_CORONAL:
                renderedSlices = [self renderCoronarImage];
                break;
            default:
                renderedSlices = [self renderSagittalImage];
                break;
        }

//        [self->mImageView setImage:cgImage imageProperties:NULL];
        
        // Hack to enable scaling down of the NSImage in the ImageView
        [renderedSlices setScalesWhenResized:YES];
        NSSize minSize;
        NSSize actualSize = [renderedSlices size];
        minSize.width = actualSize.width * 0.1f;
        minSize.height = actualSize.height * 0.1f;
        [renderedSlices setSize:minSize];
        
        [self->mImageView setImage:renderedSlices];
    }
    
    [self updateControlEnabledStates];
}

-(void)fetchPropsIfUpdated:(EDDataElement*)image
{
    if (self->mImage != image) {
        if (self->mImageMinMax != nil) [self->mImageMinMax release];
        self->mImageMinMax = [[image getMinMaxOfDataElement] retain];
        
        NSDictionary* imageProps = [image getProps:self->mPropList];
        
        if (self->mVoxelGap != nil) [self->mVoxelGap release];
        self->mVoxelGap = [[imageProps valueForKey:PROP_VOXELGAP] retain];
        
        if (self->mVoxelSize != nil) [self->mVoxelSize release];
        self->mVoxelSize = [[imageProps valueForKey:PROP_VOXELSIZE] retain];
        
        if (self->mColumnVec != nil) [self->mColumnVec release];
        self->mColumnVec = [[imageProps valueForKey:PROP_COLUMNVEC] retain];
        
        if (self->mRowVec != nil) [self->mRowVec release];
        self->mRowVec = [[imageProps valueForKey:PROP_ROWVEC] retain];

        NSLog(@"VoxelGap  %@",  self->mVoxelGap);
        NSLog(@"VoxelSize %@",  self->mVoxelSize);
        NSLog(@"ColumnVec  %@", self->mColumnVec);
        NSLog(@"RowVec %@",     self->mRowVec);
    }
}

-(NSImage*)renderAxialImage
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
            // TODO: bad access with dataset01/data.nii switch from sagi to axial
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
        
        for (int gridRow = 0; gridRow < gridHeight; gridRow++) {
            for (int gridCol = 0; gridCol < gridWidth; gridCol++) {
            
                size_t sliceNr     = gridRow * gridWidth + gridCol;
                float* sliceData   = [self->mImage getSliceData:sliceNr
                                                     atTimestep:self->mCurrentTimestep];
                
                size_t sliceOffset = ((gridRow * gridWidth * cols * rows) + gridCol * cols) * NUMBER_OF_CHANNELS;
//                NSLog(@"SliceNr: %ld, sliceOffset: %ld (rows: %ld, cols: %ld", sliceNr, sliceOffset, rows, cols);
                
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

-(NSImage*)renderSagittalImage
{
    // TODO: too much c&p from renderAxialImage ;)
    
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
                    if (gridIndex < slices) {
                        normalized = sliceData[row * cols + gridIndex] / [max floatValue];
                    } else {
                        normalized = 0.0f;
                    }
                    // ((gridRow * gridWidth * cols * rows) + gridCol * cols)
                    renderIndex = ((gridIndex / gridWidth) * gridWidth * slices * rows + (gridIndex % gridWidth) * rows + (slice * gridWidth * rows + row)) * NUMBER_OF_CHANNELS;
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

-(NSImage*)renderCoronarImage
{
    return nil;
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

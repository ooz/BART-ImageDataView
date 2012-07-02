//
//  BAImageData.m
//  ImageDataView
//
//  Created by Oliver Zscheyge on 6/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BAImageDataViewController.h"

#import "EDDataElement.h"



static const int NUMBER_OF_CHANNELS = 4;
static const float MAX_ALPHA = 1.0f;



@interface BAImageDataViewController (__privateMethods__)

-(NSImage*)renderImage;

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
        self->mImage = nil;
        self->mCurrentSlice = 0;
        self->mSliceCount   = 1;
        self->mCurrentTimestep = 0;
        
        self->mIsSingleSliceView = YES;
        
        [self.mSliceSelectSlider setMinValue:1];
        
        [self updateControlEnabledStates];
    }
    
    return self;
}

-(void)dealloc
{
    if (self->mImage != nil) {
        [self->mImage release];
    }
    
    [super dealloc];
}

-(IBAction)setOrientation:(id)sender
{
    if (sender == self.mOrientationSelect) {
        NSLog(@"Selected segment (orientation selector): %li", [self.mOrientationSelect selectedSegment]);
//        [self.mImageView setImageWithURL:[NSURL URLWithString:@"http://www.cbs.mpg.de/institute/building/mpi3n"]];
//        [self showImage:self->mImage slice:self->mCurrentSlice atTimestep:self->mCurrentTimestep];
    }
}

-(IBAction)setGridSize:(id)sender
{
    if (sender == self.mGridSizeSelect) {
        long selectedIndex = [self.mGridSizeSelect indexOfSelectedItem];
        NSLog(@"GridSize changed: %ld", selectedIndex);
        
        if (selectedIndex == 0) {
            self->mIsSingleSliceView = YES;
        } else {
            self->mIsSingleSliceView = NO;
        }
        
        [self updateControlEnabledStates];
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
        self->mImage = nil;
        [self->mImageView setImage:nil];
        
    } else {
        self->mImage = image;
        [self->mImage retain];
   
        
        BARTImageSize* imageSize = [self->mImage getImageSize];        
        self->mCurrentSlice    = sliceNr;
        self->mSliceCount      = imageSize.slices;
        self->mCurrentTimestep = tstep;
        [self updateSliceSelectors];
        
        
        NSImage* renderedSlices = [self renderImage];

//        [self->mImageView setImage:cgImage imageProperties:NULL];
        [self->mImageView setImage:renderedSlices];
        
        [renderedSlices release];
    }
    
    [self updateControlEnabledStates];
}

-(NSImage*)renderImage
{
    float* sliceData = [self->mImage getSliceData:self->mCurrentSlice 
                                       atTimestep:self->mCurrentTimestep];
    
    BARTImageSize* imageSize = [self->mImage getImageSize];
    size_t rows = imageSize.rows;
    size_t cols = imageSize.columns;
    
    NSArray* minMax = [self->mImage getMinMaxOfDataElement];
    NSNumber* max = [minMax objectAtIndex:1];
//    NSLog(@"Min: %f, max: %f", [min floatValue], [max floatValue]);
    
    float* sliceImageData = malloc(sizeof(float) * cols * rows * NUMBER_OF_CHANNELS);
    
    float normalized = 0.0f;
    for (int i = 0; i < rows * cols; i++) {
        normalized = sliceData[i] / [max floatValue];
        sliceImageData[i * NUMBER_OF_CHANNELS]     = normalized;
        sliceImageData[i * NUMBER_OF_CHANNELS + 1] = normalized;
        sliceImageData[i * NUMBER_OF_CHANNELS + 2] = normalized;
        sliceImageData[i * NUMBER_OF_CHANNELS + 3] = MAX_ALPHA;
        //            sliceData[i] =
        //            NSLog(@"%f", *(sliceData++));
    }
    
    //        NSLog(@"foo");
    
    NSSize ciImageSize;
    ciImageSize.width = cols;
    ciImageSize.height = rows;
    CIImage* ciImage = [[CIImage alloc] initWithBitmapData:[NSData dataWithBytes:sliceImageData length:cols * rows * sizeof(float) * NUMBER_OF_CHANNELS]
                                               bytesPerRow:cols * sizeof(float) * NUMBER_OF_CHANNELS
                                                      size:ciImageSize 
                                                    format:kCIFormatRGBAf 
                                                colorSpace:CGColorSpaceCreateDeviceRGB()];
    
    NSBitmapImageRep* imageRep = 
    [[[NSBitmapImageRep alloc] initWithCIImage:ciImage] autorelease];
    CGImageRef cgImage = imageRep.CGImage;
    NSImage* nsImage = [[NSImage alloc] initWithCGImage:cgImage size:ciImageSize];
    
    [ciImage release];
    free(sliceImageData);
    
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
        
        if (self->mIsSingleSliceView == YES) {
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

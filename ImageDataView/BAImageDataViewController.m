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

-(void)activateSliceSelectors;
-(void)deactivateSliceSelectors;

-(void)updateSliceSelectors;
-(void)updateSliceTextField;
-(void)updateSliceSlider;

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
        
        [self.mSliceSelectSlider setMinValue:1];
        
        [self deactivateSliceSelectors];
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
        
//        if (selectedIndex == 0) {
//            [self activateSliceSelectors];
//        } else {
//            [self deactivateSliceSelectors];
//        }
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
        [self deactivateSliceSelectors];
        
    } else {
        self->mImage = image;
        [self->mImage retain];
   
        BARTImageSize* imageSize = [self->mImage getImageSize];
        size_t rows = imageSize.rows;
        size_t cols = imageSize.columns;
        size_t slices = imageSize.slices;
//        size_t timesteps = imageSize.timesteps;
//        NSLog(@"%zu, %zu, %zu, %zu", cols, rows, slices, timesteps);
        
        self->mCurrentSlice    = sliceNr;
        self->mSliceCount      = slices;
        self->mCurrentTimestep = tstep;
        [self updateSliceSelectors];

        float* sliceData = [self->mImage getSliceData:sliceNr atTimestep:tstep];
        
        NSArray* minMax = [self->mImage getMinMaxOfDataElement];
        NSNumber* max = [minMax objectAtIndex:1];
//        NSLog(@"Min: %f, max: %f", [min floatValue], [max floatValue]);
        
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
//        NSLog(@"%@", ciImage);
        NSImage* nsImage = [[NSImage alloc] initWithCGImage:cgImage size:ciImageSize];
//        [self->mImageView setImage:cgImage imageProperties:NULL];
        [self->mImageView setImage:nsImage];
        [self activateSliceSelectors];
        
        [nsImage release];
        
        [ciImage release];
        free(sliceImageData);
    }
}


-(void)activateSliceSelectors
{
    [self.mSliceSelect setEnabled:YES];
    [self.mSliceSelectSlider setEnabled:YES];
}

-(void)deactivateSliceSelectors
{
    [self.mSliceSelect setEnabled:NO];
    [self.mSliceSelectSlider setEnabled:NO];
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

@end

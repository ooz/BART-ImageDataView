//
//  BAImageData.m
//  ImageDataView
//
//  Created by Oliver Zscheyge on 6/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BAImageDataViewController.h"

#import "BAImageDataViewConstants.h"
#import "BABrainImageView.h"
#import "BAImageSliceSelector.h"
#import "BADataElementRenderer.h"

#include <math.h>


// #############
// # Constants #
// #############

/** Initial size of the NSDictionary used to store overlays. */
static const NSUInteger INITIAL_OVERLAY_CAPACITY = 8;


// ###############################
// # Private method declarations #
// ###############################

@interface BAImageDataViewController (__privateMethods__)

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
 * Methods to render the actual NSImage object displayed in the view.
 * Regardless of single or multi slice view only one NSImage object is rendered.
 */
-(NSImage*)renderImage;
-(NSImage*)renderIdenticalImage          :(BOOL)flipX :(BOOL)flipY :(BOOL)flipZ;
-(NSImage*)renderTurnUpImage             :(BOOL)flipX :(BOOL)flipY :(BOOL)flipZ;
-(NSImage*)renderTurnLeftRotateRightImage:(BOOL)flipX :(BOOL)flipY :(BOOL)flipZ;
-(NSImage*)renderTurnLeftImage           :(BOOL)flipX :(BOOL)flipY :(BOOL)flipZ;
-(NSImage*)renderTurnUpRotateRightImage  :(BOOL)flipX :(BOOL)flipY :(BOOL)flipZ;

/**
 * Utility method for the render methods.
 * Constructs a NSImage object from a float vector. The vector is not freed in the process!
 *
 * \param data Float array containing all needed bytes for all channels.
 * \param len  Length of the data float array.
 * \param bpr  Bytes per row in the resulting image. 
 *             This has to respect the size of the data type (float) as well as the number of channels.
 * \param w    Width  of the target NSImage in pixels.
 * \param h    Height of the target NSImage in pixels.
 * \return     Autoreleased NSImage rendering the float data.
 */
-(NSImage*)imageFromFloat:(float*)data 
                   length:(size_t)len 
              bytesPerRow:(size_t)bpr
                    width:(size_t)w
                   height:(size_t)h;

/**
 * Updates the size of a NSImage object based on the physical size of the
 * EDDataElement to be displayed. This respects voxel size and gap of the image.
 */
-(NSImage*)fixSizeOf:(NSImage*)image 
                with:(BARTImageSize*)dataSize;

/**
 * Methods to update view objects based on internal state changes.
 */
-(void)updateSliceSelectors;
-(void)updateSliceTextField;
-(void)updateSliceSlider;

/**
 * Methods to enable/disable certain view components that may be needed/not needed
 * in single slice/multi slice view.
 */
-(void)updateControlEnabledStates;
-(void)setOrientationAndGridSizeSelectorStates:(BOOL)enabled;
-(void)setSliceSelectorStates:(BOOL)enabled;

@end



// ##################
// # Implementation #
// ##################

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
        BAImageSliceSelector* sliceSelector = [[BAImageSliceSelector alloc] init];
        self->mRenderer = [[BADataElementRenderer alloc] initWithSliceSelector:sliceSelector];
        [sliceSelector release];
        
        self->mOverlays = [[NSMutableDictionary alloc] initWithCapacity:INITIAL_OVERLAY_CAPACITY];
        
        self->mGridSize = (NSSize) { DEFAULT_GRID_SIZE
                                   , DEFAULT_GRID_SIZE };
        
        [self showImage:nil];
    }
    
    return self;
}

-(void)dealloc
{
    if (self->mRenderer != nil) [self->mRenderer release];
    
    [self->mOverlays release];
    
    [super dealloc];
}

-(IBAction)setOrientation:(id)sender
{
    if (sender == self.mOrientationSelect) {
        NSInteger orientationSelectionIndex = [self.mOrientationSelect selectedSegment];
//        NSLog(@"Selected segment (orientation selector): %li", orientationSelectionIndex);
        
        
        enum ImageOrientation viewOrientation;
        switch (orientationSelectionIndex) {
            case 1:
                viewOrientation = ORIENT_AXIAL;
                break;
            case 2:
                viewOrientation = ORIENT_CORONAL;
                break;
            default:
                viewOrientation = ORIENT_SAGITTAL;
                break;
        }

        [self->mRenderer setTargetOrientation:viewOrientation];
        [self showImage:[self->mRenderer getDataElement] 
                  slice:[self->mRenderer getCurrentSlice]
             atTimestep:[self->mRenderer getCurrentTimestep]];
    }
}

-(IBAction)setGridSize:(id)sender
{
    if (sender == self.mGridSizeSelect) {
        long selectedIndex = [self.mGridSizeSelect indexOfSelectedItem];
//        NSLog(@"GridSize changed: %ld", selectedIndex);
        
        if (selectedIndex == 1) {
            self->mGridSize = (NSSize) { GRID_SIZE_SIX
                                       , GRID_SIZE_SIX };
        } else {
            self->mGridSize = (NSSize) { DEFAULT_GRID_SIZE
                                       , DEFAULT_GRID_SIZE };
        }
                    
//        NSLog(@"Grid size: %2.0f, %2.0f", self->mGridSize.width, self->mGridSize.height);
        
        [self->mRenderer setGridSize:self->mGridSize];
        [self showImage:[self->mRenderer getDataElement] 
                  slice:[self->mRenderer getCurrentSlice]
             atTimestep:[self->mRenderer getCurrentTimestep]];
    }
}

-(IBAction)selectSlice:(id)sender
{
    int sliceNr = [sender intValue] - 1;
    
    [self showImage:[self->mRenderer getDataElement] 
              slice:sliceNr
         atTimestep:[self->mRenderer getCurrentTimestep]];
}

-(void)showImage:(EDDataElement*)image
{
    [self showImage:image slice:0 atTimestep:0];
}

-(void)showImage:(EDDataElement*)image
           slice:(uint)sliceNr
      atTimestep:(uint)tstep
{
    [self->mRenderer setData:image slice:sliceNr timestep:tstep];
    [self->mImageView setBackgroundImage:[self->mRenderer renderImage]];
    
    [self updateSliceSelectors];
    [self updateControlEnabledStates];
}

-(void)setBackgroundImage:(EDDataElement*)image
{
    [self showImage:image];
}

-(void)setOverlayImage:(EDDataElement*)image withID:(NSString*)identifier
{
    if (identifier != nil) {
        [self->mOverlays setObject:image forKey:identifier];
    }
    // TODO: Update GUI dropdown!
}

-(void)removeOverlay:(NSString*)identifier
{
    [self->mOverlays removeObjectForKey:identifier];
    // TODO: Update GUI dropdown!
}

-(void)updateSliceSelectors
{
    [self updateSliceTextField];
    [self updateSliceSlider];
}

-(void)updateSliceTextField
{
    [self.mSliceSelect setStringValue:[NSString stringWithFormat:@"%d/%ld", 
                                       ([self->mRenderer getCurrentSlice] + 1),     // Display natural indices starting with 1
                                       [self->mRenderer getSliceCount]]];
}

-(void)updateSliceSlider
{
    [self.mSliceSelectSlider setIntValue:[self->mRenderer getCurrentSlice]];        // Same thing with the slider
    [self.mSliceSelectSlider setMaxValue:[self->mRenderer getSliceCount]];
}

-(void)updateControlEnabledStates
{
    if ([self->mRenderer getDataElement] != nil) {
        // Activate orientation selection, slice grid selection
        [self setOrientationAndGridSizeSelectorStates:YES];
        
        if (   self->mGridSize.width  == DEFAULT_GRID_SIZE 
            && self->mGridSize.height == DEFAULT_GRID_SIZE) {
            [self setSliceSelectorStates:YES];
        } else {
            [self setSliceSelectorStates:NO];
        }
        
    } else {
        // Deactivate all controls
        [self setOrientationAndGridSizeSelectorStates:NO];
        [self setSliceSelectorStates:NO];
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

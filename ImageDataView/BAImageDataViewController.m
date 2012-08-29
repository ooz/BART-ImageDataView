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

/** Initializes all GUI elements related to overlays/colortables. */
-(void)initOverlayColortableComponents;

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

@synthesize mOverlaySelect;
@synthesize mColortableSelect;
@synthesize mRegion1LowerField;
@synthesize mRegion1LowerStepper;
@synthesize mRegion1UpperField;
@synthesize mRegion1UpperStepper;
@synthesize mRegion2LowerField;
@synthesize mRegion2LowerStepper;
@synthesize mRegion2UpperField;
@synthesize mRegion2UpperStepper;

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
        
//        [self initOverlayColortableComponents];
        
        [self showImage:nil];
    }
    
    return self;
}

-(void)awakeFromNib
{
//    [self->mOverlaySelect removeAllItems];
//    [self->mOverlaySelect setTitle:@"Overlay selection"];
//    [self->mOverlaySelect setEnabled:NO];
//    [self->mColortableSelect removeAllItems];
    [self->mColortableSelect addItemWithTitle:@"Colortable 1"];
    [self->mColortableSelect addItemWithTitle:@"Colortable 2"];
    
    
    // TODO: use formatter for text fields!
//    [self->mRegion1LowerField   setValue:[NSNumber numberWithDouble:0.0]];
    [self->mRegion1LowerStepper setValue:[NSNumber numberWithDouble:0.0]];
//    [self->mRegion1UpperField   setValue:[NSNumber numberWithDouble:0.0]];
    [self->mRegion1UpperStepper setValue:[NSNumber numberWithDouble:0.0]];
    
    [self->mRegion2LowerField   setEnabled:NO];
    [self->mRegion2LowerStepper setEnabled:NO];
    [self->mRegion2UpperField   setEnabled:NO];
    [self->mRegion2UpperStepper setEnabled:NO];
}

//-(void)initOverlayColortableComponents
//{
//    
//    [self awa]
//}

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


// ##########################################
// # Overlay and colortable related actions #
// ##########################################

-(IBAction)setOverlay:(id)sender
{

}

-(IBAction)setColortable:(id)sender
{
    
}

-(IBAction)setRegion1Bounds:(id)sender
{
    
}

-(IBAction)setRegion2Bounds:(id)sender
{
    
}

@end

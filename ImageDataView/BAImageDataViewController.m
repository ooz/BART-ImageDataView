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
 * Renders back- and foreground and passes the image objects to the view
 * class for display.
 */
-(void)updateViewImages;

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

/** Updates the min/max values of the NSStepper components used for the colortable regions. */
-(void)updateStepperMinMax;

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

@synthesize mRegion1Lower;
@synthesize mRegion1Upper;
@synthesize mRegion2Lower;
@synthesize mRegion2Upper;

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
        
        sliceSelector = [[BAImageSliceSelector alloc] init];
        self->mOverlayRenderer = [[BADataElementRenderer alloc] initWithSliceSelector:sliceSelector];
        [sliceSelector release];
        
        self->mOverlays = [[NSMutableDictionary alloc] initWithCapacity:INITIAL_OVERLAY_CAPACITY];
        
        self->mGridSize = (NSSize) { DEFAULT_GRID_SIZE
                                   , DEFAULT_GRID_SIZE };
        
//        [self initOverlayColortableComponents];
        
        [self updateViewImages];
    }
    
    return self;
}

-(void)awakeFromNib
{
//    [self->mOverlaySelect removeAllItems];
    [self->mOverlaySelect addItemWithTitle:@"Overlay selection"];
    [self->mOverlaySelect setEnabled:NO];
//    [self->mColortableSelect removeAllItems];
    [self->mColortableSelect addItemWithTitle:@"Colortable 1"];
    [self->mColortableSelect addItemWithTitle:@"Colortable 2"];
    
    // TODO: use formatter for text fields!
//    [self->mRegion1LowerField   setValue:[NSNumber numberWithDouble:0.0]];
//    [self->mRegion1LowerStepper setValue:[NSNumber numberWithDouble:0.0]];
//    [self->mRegion1UpperField   setValue:[NSNumber numberWithDouble:0.0]];
//    [self->mRegion1UpperStepper setValue:[NSNumber numberWithDouble:0.0]];
    
    [self->mRegion2LowerField   setEnabled:NO];
    [self->mRegion2LowerStepper setEnabled:NO];
    [self->mRegion2UpperField   setEnabled:NO];
    [self->mRegion2UpperStepper setEnabled:NO];
    
    NSImage* iconImage;
    iconImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleWithIdentifier:BUNDLE_ID] pathForResource: @"Sagittal" ofType: @"png"]];
    [self->mOrientationSelect setImage:iconImage forSegment:0];
    [iconImage release];
    iconImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleWithIdentifier:BUNDLE_ID] pathForResource: @"Axial" ofType: @"png"]];
    [self->mOrientationSelect setImage:iconImage forSegment:1];
    [iconImage release];
    iconImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleWithIdentifier:BUNDLE_ID] pathForResource: @"Coronal" ofType: @"png"]];
    [self->mOrientationSelect setImage:iconImage forSegment:2];
    [iconImage release];
    
    [self updateViewImages];
}

//-(void)initOverlayColortableComponents
//{
//    
//    [self awa]
//}

-(void)dealloc
{
    if (self->mRenderer != nil) [self->mRenderer release];
    if (self->mOverlayRenderer != nil) [self->mOverlayRenderer release];
    
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
        [self->mOverlayRenderer setTargetOrientation:viewOrientation];
        
        [self updateViewImages];
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
        [self->mOverlayRenderer setGridSize:self->mGridSize];
        
        [self updateViewImages];
    }
}

-(IBAction)selectSlice:(id)sender
{
    int sliceNr = [sender intValue] - 1;
    
    [self->mRenderer setSlice:sliceNr];
    [self->mOverlayRenderer setSlice:sliceNr];
    
    [self updateViewImages];
}

-(void)setBackgroundImage:(EDDataElement*)image
{
    [self->mRenderer setData:image];
    
    [self updateViewImages];
}

-(void)addOverlayImage:(EDDataElement*)image withID:(NSString*)identifier
{
    if (image != nil && identifier != nil) {
        [self->mOverlays setObject:image forKey:identifier];
        [self->mOverlaySelect addItemWithTitle:identifier];
        [self->mOverlaySelect setEnabled:YES];
    }
}

-(void)showOverlay:(NSString*)identifier
{
    // TODO
}
-(void)hideOverlay:(NSString*)identifier
{
    // TODO
}

-(EDDataElement*)getOverlayBy:(NSString*)identifier
{
    return [self->mOverlays objectForKey:identifier];
}

-(NSArray*)overlayIDs
{
    return [self->mOverlays allKeys];
}

-(void)removeOverlay:(NSString*)identifier
{
    [self->mOverlays removeObjectForKey:identifier];
    // TODO: Update GUI dropdown!
}

-(void)updateViewImages
{
    [self->mImageView setBackgroundImage:[self->mRenderer renderImage]];
    [self->mImageView setForegroundImage:[self->mOverlayRenderer renderImage]];
    
    [self updateStepperMinMax];
    [self updateSliceSelectors];
    [self updateControlEnabledStates];
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

-(void)updateStepperMinMax
{
    NSArray* minMax = [self->mRenderer getDataMinMax];
    
    double min = 0.0;
    double max = 0.0;
    if (minMax != nil) {
        min = [[minMax objectAtIndex:0] doubleValue];
        max = [[minMax objectAtIndex:1] doubleValue];
    }
    
    [self->mRegion1LowerStepper setMinValue:min];
    [self->mRegion1LowerStepper setMaxValue:max];
    [self->mRegion1UpperStepper setMinValue:min];
    [self->mRegion1UpperStepper setMaxValue:max];
    
    [self->mRegion2LowerStepper setMinValue:min];
    [self->mRegion2LowerStepper setMaxValue:max];
    [self->mRegion2UpperStepper setMinValue:min];
    [self->mRegion2UpperStepper setMaxValue:max];
}


// ##########################################
// # Overlay and colortable related actions #
// ##########################################

-(IBAction)setOverlay:(id)sender
{
    if (sender == self->mOverlaySelect) {
        NSString* selection = [self->mOverlaySelect titleOfSelectedItem];
        EDDataElement* overlay = [self->mOverlays objectForKey:selection];
        
        if (overlay != nil) {
            [self->mOverlayRenderer setData:overlay slice:[self->mRenderer getCurrentSlice] timestep:[self->mRenderer getCurrentTimestep]];
            [self->mImageView setForegroundImage:[self->mOverlayRenderer renderImage]];
        }
    }
}

-(IBAction)setColortable:(id)sender
{
    
}

-(IBAction)setRegion1Bounds:(id)sender
{
    float tfLower = [self->mRegion1LowerField floatValue];
    if (tfLower < [self->mRegion1LowerStepper minValue]) {
        [self->mRegion1LowerField setFloatValue:[self->mRegion1LowerStepper minValue]];
    }
    if (tfLower > [self->mRegion1LowerStepper maxValue]) {
        [self->mRegion1LowerField setFloatValue:[self->mRegion1LowerStepper maxValue]];
    }
    
    float tfUpper = [self->mRegion1UpperField floatValue];
    if (tfUpper < [self->mRegion1UpperStepper minValue]) {
        [self->mRegion1UpperField setFloatValue:[self->mRegion1UpperStepper minValue]];
    }
    if (tfUpper > [self->mRegion1UpperStepper maxValue]) {
        [self->mRegion1UpperField setFloatValue:[self->mRegion1UpperStepper maxValue]];
    }
}

-(IBAction)setRegion2Bounds:(id)sender
{
    float tfLower = [self->mRegion2LowerField floatValue];
    if (tfLower < [self->mRegion2LowerStepper minValue]) {
        [self->mRegion2LowerField setFloatValue:[self->mRegion2LowerStepper minValue]];
    }
    if (tfLower > [self->mRegion2LowerStepper maxValue]) {
        [self->mRegion2LowerField setFloatValue:[self->mRegion2LowerStepper maxValue]];
    }
    
    float tfUpper = [self->mRegion2UpperField floatValue];
    if (tfUpper < [self->mRegion2UpperStepper minValue]) {
        [self->mRegion2UpperField setFloatValue:[self->mRegion2UpperStepper minValue]];
    }
    if (tfUpper > [self->mRegion2UpperStepper maxValue]) {
        [self->mRegion2UpperField setFloatValue:[self->mRegion2UpperStepper maxValue]];
    }
}

@end

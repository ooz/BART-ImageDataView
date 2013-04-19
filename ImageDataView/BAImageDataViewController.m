//
//  BAImageData.m
//  ImageDataView
//
//  Created by Oliver Zscheyge on 6/21/12.
//  Copyright (c) 2012 MPI CBS. All rights reserved.
//

#import "BAImageDataViewController.h"

#import "BAImageDataViewConstants.h"
#import "BABrainImageView.h"

#import "BAImageSliceSelector.h"
#import "BADataElementRenderer.h"

#import "BASingleDomainColortableFilter.h"
#import "BATwoDomainColortableFilter.h"

#import "ROI/BAROIController.h"



#include <math.h>


// #############
// # Constants #
// #############

/** Text shown in the overlay selection drop down if no overlay is available. */
static NSString* DEFAULT_OVERLAY_TEXT = @"Overlay selection";
/** Drop down option text to disable the current overlay. */
static NSString* NO_OVERLAY_TEXT      = @"No overlay";

/** Drop down text for the first colortable (one domain). */
static NSString* COLORTABLE_ONE_TEXT  = @"Colortable 1";
/** Drop down text for the second colortable (two domains). */
static NSString* COLORTABLE_TWO_TEXT  = @"Colortable 2";

/** Initial size of the NSDictionary used to store overlays. */
static const NSUInteger INITIAL_OVERLAY_CAPACITY = 8;

/** Mask flag telling to use the min/max input elements for the first region. */
static const NSUInteger FIRST_REGION_SELECTION_MASK  = 1 << 0;
/** Mask flag telling to use the min/max input elements for the second region. */
static const NSUInteger SECOND_REGION_SELECTION_MASK = 1 << 1;

/** Title of the window containing the ROI toolbox. */
static NSString* ROI_TOOLBOX_WINDOW_TITLE = @"ROI Selection Toolbox";


// ###############################
// # Private method declarations #
// ###############################

@interface BAImageDataViewController (__privateMethods__)

/**
 * Renders back- and foreground and passes the image objects to the view
 * class for display.
 */
-(void)updateViewImages;

/**
 * Update the image filters applied to overlay with new min/max values.
 *
 * \param mask Mask telling region(s) which min/max ranges need to be updated.
 */
-(void)updateFilterBounds:(NSUInteger)mask;

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
/**
 * Enable/disable the textfields and steppers used to select the colortable region(s).
 *
 * \param mask    Mask telling the region selection components (textfield/stepper)
 *                of which region to enable/disable.
 * \param enabled Flag to enable (YES) or disable (NO) the region selection components.
 */
-(void)setRegionSelectionStates:(NSUInteger)mask to:(BOOL)enabled;

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

@synthesize mROIToolboxButton;

-(id)init
{
    if (self = [super initWithNibName:@"BAImageDataView" bundle:nil]) {
        self->mROIController = [[BAROIController alloc] init];
        self->mROIToolboxWindow = nil;
        
        BAImageSliceSelector* sliceSelector = [[BAImageSliceSelector alloc] init];
        self->mRenderer = [[BADataElementRenderer alloc] initWithSliceSelector:sliceSelector];
        [sliceSelector release];
        
        sliceSelector = [[BAImageSliceSelector alloc] init];
        self->mOverlayRenderer = [[BADataElementRenderer alloc] initWithSliceSelector:sliceSelector];
        [sliceSelector release];
        
        BAImageFilter* imageFilter = [[BASingleDomainColortableFilter alloc] init];
        [self->mOverlayRenderer setImageFilter:imageFilter];
        [imageFilter release];
        
        self->mOverlays = [[NSMutableDictionary alloc] initWithCapacity:INITIAL_OVERLAY_CAPACITY];
        
        self->mGridSize = (NSSize) { DEFAULT_GRID_SIZE
            , DEFAULT_GRID_SIZE };
    }
    
    return self;
}

-(void)awakeFromNib
{
    [self->mOverlaySelect addItemWithTitle:DEFAULT_OVERLAY_TEXT];
    [self->mOverlaySelect setEnabled:NO];
    
    [self->mColortableSelect addItemWithTitle:COLORTABLE_ONE_TEXT];
    [self->mColortableSelect addItemWithTitle:COLORTABLE_TWO_TEXT];
    [self->mColortableSelect setEnabled:NO];
    
    // TODO: use formatter for text fields!
//    [self->mRegion1LowerField   setValue:[NSNumber numberWithDouble:0.0]];
//    [self->mRegion1LowerStepper setValue:[NSNumber numberWithDouble:0.0]];
//    [self->mRegion1UpperField   setValue:[NSNumber numberWithDouble:0.0]];
//    [self->mRegion1UpperStepper setValue:[NSNumber numberWithDouble:0.0]];
    
    [self setRegionSelectionStates:( FIRST_REGION_SELECTION_MASK 
                                   |SECOND_REGION_SELECTION_MASK) 
                                to:NO];
    
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
    
    [self.mImageView setNextResponder:self];
    
    [self updateViewImages];
}

-(void)dealloc
{
    if (self->mRenderer != nil) [self->mRenderer release];
    if (self->mOverlayRenderer != nil) [self->mOverlayRenderer release];
    
    [self->mOverlays release];
    
    [self->mROIToolboxWindow release];
    [self->mROIController release];
    
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
        if ([self->mOverlays count] == 0) {
            [self->mOverlaySelect removeAllItems];
            [self->mOverlaySelect addItemWithTitle:NO_OVERLAY_TEXT];
            [self->mOverlaySelect setEnabled:YES];
        }
        
        [self->mOverlays setObject:image forKey:identifier];
        
        [self->mOverlaySelect addItemWithTitle:identifier];
    }
}

-(void)showOverlay:(NSString*)identifier
{
    EDDataElement* overlay = [self->mOverlays objectForKey:identifier];
    
    if (overlay != nil) {
        [self->mOverlayRenderer setData:overlay slice:[self->mRenderer getCurrentSlice] timestep:[self->mRenderer getCurrentTimestep]];
        
        [self updateStepperMinMax];
        [self updateFilterBounds:(FIRST_REGION_SELECTION_MASK | SECOND_REGION_SELECTION_MASK)];
        
        [self updateViewImages];
    }
}
-(void)hideOverlay:(NSString*)identifier
{
    EDDataElement* overlay = [self->mOverlays objectForKey:identifier];
    
    if (overlay != nil && overlay == [self->mOverlayRenderer getDataElement]) {
        [self->mOverlayRenderer setData:nil];
        
        [self updateViewImages];
    }
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
    [self hideOverlay:identifier];
    
    [self->mOverlays removeObjectForKey:identifier];
    
    if ([self->mOverlays count] == 0) {
        [self->mOverlaySelect removeAllItems];
        [self->mOverlaySelect addItemWithTitle:DEFAULT_OVERLAY_TEXT];
        [self->mOverlaySelect setEnabled:NO];
        [self->mColortableSelect setEnabled:NO];
        [self setRegionSelectionStates:(FIRST_REGION_SELECTION_MASK | SECOND_REGION_SELECTION_MASK) 
                                    to:NO];
    
    } else if ([self->mOverlaySelect indexOfItemWithTitle:identifier] != -1) {
        [self->mOverlaySelect removeItemWithTitle:identifier];
    }
}

-(void)updateViewImages
{
    [self->mImageView setImages:nil
                             on:[self->mOverlayRenderer renderImage:NO]
                             on:[self->mRenderer renderImage:NO]];

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
    [self.mSliceSelect setStringValue:[NSString stringWithFormat:@"%d/%d", 
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
    NSArray* minMax = [self->mOverlayRenderer getDataMinMax];
    
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
        
        if ([selection isEqualToString:NO_OVERLAY_TEXT]) {
            [self->mOverlayRenderer setData:nil];
            [self updateViewImages];
            [self->mColortableSelect setEnabled:NO];
            [self setRegionSelectionStates:(FIRST_REGION_SELECTION_MASK | SECOND_REGION_SELECTION_MASK) 
                                        to:NO];
            
        } else {
            [self showOverlay:selection];
            [self->mColortableSelect setEnabled:YES];
            [self setColortable:self->mColortableSelect];
        }
    }
}

-(IBAction)setColortable:(id)sender
{
    if (sender == self->mColortableSelect) {
        NSInteger selectedIndex = [self->mColortableSelect indexOfSelectedItem];
 
        if (selectedIndex == 0) {
            BAImageFilter* imageFilter = [[BASingleDomainColortableFilter alloc] init];
            [self->mOverlayRenderer setImageFilter:imageFilter];
            [imageFilter release];
            
            [self setRegionSelectionStates:FIRST_REGION_SELECTION_MASK to:YES];
            [self setRegionSelectionStates:SECOND_REGION_SELECTION_MASK to:NO];
        
        } else if (selectedIndex == 1) {
            BAImageFilter* imageFilter = [[BATwoDomainColortableFilter alloc] init];
            [self->mOverlayRenderer setImageFilter:imageFilter];
            [imageFilter release];
            
            [self setRegionSelectionStates:(FIRST_REGION_SELECTION_MASK | SECOND_REGION_SELECTION_MASK) to:YES];
        }
        
        [self updateFilterBounds:(FIRST_REGION_SELECTION_MASK | SECOND_REGION_SELECTION_MASK)];
    }
}

-(void)setRegionSelectionStates:(NSUInteger)mask 
                             to:(BOOL)enabled
{
    if ((mask & FIRST_REGION_SELECTION_MASK) == FIRST_REGION_SELECTION_MASK) {
        [self->mRegion1LowerField   setEnabled:enabled];
        [self->mRegion1LowerStepper setEnabled:enabled];
        [self->mRegion1UpperField   setEnabled:enabled];
        [self->mRegion1UpperStepper setEnabled:enabled];
    }
    
    if ((mask & SECOND_REGION_SELECTION_MASK) == SECOND_REGION_SELECTION_MASK) {
        [self->mRegion2LowerField   setEnabled:enabled];
        [self->mRegion2LowerStepper setEnabled:enabled];
        [self->mRegion2UpperField   setEnabled:enabled];
        [self->mRegion2UpperStepper setEnabled:enabled];
    }
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
    
    [self updateFilterBounds:FIRST_REGION_SELECTION_MASK];
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
    
    [self updateFilterBounds:SECOND_REGION_SELECTION_MASK];
}

-(void)updateFilterBounds:(NSUInteger)mask
{
    // Update min/max in overlay filters
    BAImageFilter* filter = [self->mOverlayRenderer getImageFilter];
    if (filter != nil) {
        
        if ((mask & FIRST_REGION_SELECTION_MASK) == FIRST_REGION_SELECTION_MASK) {
            float tfLower = [self->mRegion1LowerField floatValue];
            float tfUpper = [self->mRegion1UpperField floatValue];
            float min = [self->mRegion1LowerStepper minValue];
            float max = [self->mRegion1LowerStepper maxValue];
            
            // TODO: Compute exact normalized value respecting all signum cases of min/max
            [filter setValue:[NSNumber numberWithFloat:tfLower / max] forKey:@"minimum"];
            [filter setValue:[NSNumber numberWithFloat:tfUpper / max] forKey:@"maximum"];
        }
        
        if ((mask & SECOND_REGION_SELECTION_MASK) == SECOND_REGION_SELECTION_MASK) {
            float tfLower = [self->mRegion2LowerField floatValue];
            float tfUpper = [self->mRegion2UpperField floatValue];
            float min = [self->mRegion2LowerStepper minValue];
            float max = [self->mRegion2LowerStepper maxValue];
            
            // TODO: Compute exact normalized value respecting all signum cases of min/max
            [filter setValue:[NSNumber numberWithFloat:tfLower / max] forKey:@"minimum2"];
            [filter setValue:[NSNumber numberWithFloat:tfUpper / max] forKey:@"maximum2"];
        }
        
        [self updateViewImages];
    }
}


// #######
// # ROI #
// #######

-(IBAction)toggleROIToolbox:(id)sender
{
    if (sender == self->mROIToolboxButton) {
        if (self->mROIToolboxWindow == nil) {
            [self->mROIController loadView];
            
            NSSize roiViewSize = [[self->mROIController view] bounds].size;
            self->mROIToolboxWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(0.0, 0.0, roiViewSize.width, roiViewSize.height)
                                                                  styleMask:NSTitledWindowMask | NSClosableWindowMask
                                                                    backing:NSBackingStoreBuffered
                                                                      defer:YES];
            [self->mROIToolboxWindow setTitle:ROI_TOOLBOX_WINDOW_TITLE];
            [self->mROIToolboxWindow setContentView:[self->mROIController view]];
            [self->mROIToolboxWindow setReleasedWhenClosed:NO];
            [self->mROIToolboxWindow center];
            [self->mROIToolboxWindow setIsVisible:YES];
        
        } else {
            [self->mROIToolboxWindow setIsVisible:![self->mROIToolboxWindow isVisible]];
        }
    }
}


// ################
// # Mouse events #
// ################

-(void)mouseUp:(NSEvent*)theEvent {
    NSPoint clickPoint = [theEvent locationInWindow];
    NSLog(@"BAImageDataViewController mouseUp event, p: (%.1lf, %.1lf)", clickPoint.x, clickPoint.y);
    
    NSArray* clickInDataSpace = [self->mRenderer pointToVoxel:clickPoint];
    NSLog(@"BAImageDataViewController clickInDataSpace: %@", clickInDataSpace);
    
    [[self->mRenderer getDataElement] setVoxelValue:[NSNumber numberWithFloat:1300.0]
                                              atRow:[[clickInDataSpace objectAtIndex:1] unsignedIntegerValue]
                                                col:[[clickInDataSpace objectAtIndex:0] unsignedIntegerValue]
                                              slice:[[clickInDataSpace objectAtIndex:2] unsignedIntegerValue]
                                           timestep:[[clickInDataSpace objectAtIndex:3] unsignedIntegerValue]];
    
    // Force rerender since original DataElement has changed
    [self->mRenderer renderImage:YES];
    [self updateViewImages];
}

@end

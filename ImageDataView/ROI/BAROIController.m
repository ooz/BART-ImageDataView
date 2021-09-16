//
//  BAROIController.m
//  ImageDataView
//
//  Created by Oliver Z. on 4/18/13.
//
//

#import "BAROIController.h"
#import "EDDataElement.h"
#import "BADataVoxel.h"
#import "BAROIPointRangeSelection.h"
#import "BADataElementRenderer.h"


// #############
// # Constants #
// #############

/** Text shown in the ROI drop-down when there isn't any ROI in the system yet. */
static NSString* DEFAULT_ROI_TEXT = @"No ROI available";


// ###############################
// # Private method declarations #
// ###############################

@interface BAROIController (__privateMethods__)

/** Updates the enabled state of view components. */
-(void)updateViewStates;

/**
 * Checks dimensions, main orientation and voxel attributes (e.g. spacing, size)
 * of two EDDataElements.
 *
 * \param data  EDDataElement to check against other.
 * \param other EDDataElement to check against data.
 * \return      Boolean indictating whether both data elements have the same size,
 *              spacing etc. attributes (= are compatible).
 */
-(BOOL)isCompatible:(EDDataElement*)data
               with:(EDDataElement*)other;

/** Creates a BAROISelection object from the given parameters and 
 *  the current view state.
 *
 * \param data       EDDataElement defining the image space
 * \param clickPoint 4D point that was clicked within the parameter data.
 * \param min        Float minimum voxel value of data that should be selected.
 * \param max        Float maximum voxel value of data that should be selected.
 * \return           BAROISelection taking both given paraemters and the 
 *                   current view state into account.
 */
-(BAROISelection*)makeSelectionFrom:(EDDataElement*)data
                                 at:(BADataVoxel*)clickPoint
                            inRange:(float)min
                                and:(float)max;

@end


// ##################
// # Implementation #
// ##################

@implementation BAROIController

@synthesize mToolSelect;
@synthesize mModeSelect;
@synthesize mROISelect;

-(id)init
{
    if (self = [super initWithNibName:@"BAROIToolboxView" bundle:nil]) {
        self->mROISelectionRenderer = nil;
        self->mROISelections = [[NSMutableDictionary alloc] init];
        self->mROIMasks      = [[NSMutableDictionary alloc] init];
        self->mMode = ADD;
        self->mThreshold = 0.0f;
    }
    return self;
}

-(id)initWithROISelectionRenderer:(BADataElementRenderer*)r
{
    if (self = [self init]) {
        self->mROISelectionRenderer = [r retain];
    }
    
    return self;
}

-(void)awakeFromNib
{
    [self->mROISelect removeAllItems];
    [self->mROISelect addItemWithTitle:DEFAULT_ROI_TEXT];
    
    [self updateViewStates];
}

-(void)dealloc
{
    [self->mROISelectionRenderer release];
    [self->mROISelections release];
    [self->mROIMasks release];
    
    [super dealloc];
}


// ###############
// # GUI methods #
// ###############

-(IBAction)setTool:(id)sender
{
    long selectedIndex = [sender indexOfSelectedItem];
    
    NSLog(@"Selected tool: %ld", selectedIndex);
}

-(IBAction)setMode:(id)sender
{
    if (sender == self->mModeSelect) {
        long selectedIndex = [sender indexOfSelectedItem];
        switch (selectedIndex) {
            case 0:
                self->mMode = ADD;
                break;
            case 1:
                self->mMode = REMOVE;
                break;
            default:
                self->mMode = ADD;
                break;
        }
    }
}

-(IBAction)setROI:(id)sender
{
    NSString* currentROI = [[self->mROISelect selectedItem] title];
    [self->mROISelectionRenderer setData:[self->mROIMasks valueForKey:currentROI]];
    [self->mROISelectionRenderer renderImage:NO];
}

-(void)updateViewStates
{
    if ([self->mROISelections count] == 0) {
        [self->mROISelect setEnabled:NO];
        [self->mToolSelect setEnabled:NO];
        [self->mModeSelect setEnabled:NO];
    } else {
        [self->mROISelect setEnabled:YES];
        [self->mToolSelect setEnabled:YES];
        [self->mModeSelect setEnabled:YES];
    }
}


// ###################
// # Regular methods #
// ###################

-(void)addROI:(NSString*)label
{
    if (label != nil) {
        if ([self->mROISelections count] == 0) {
            [self->mROISelect removeAllItems];
        }
        
        BAROISelection* roiSelection = [[BAROISelection alloc] init];
        [self->mROISelections setValue:roiSelection forKey:label];
        [self->mROIMasks      setValue:nil          forKey:label];
        [self->mROISelect addItemWithTitle:label];
        [roiSelection release];
        
        [self updateViewStates];
    }    
}

-(void)removeROI:(NSString*)label
{
    [self->mROISelections removeObjectForKey:label];
    [self->mROIMasks      removeObjectForKey:label];
    
    if ([self->mROISelections count] == 0) {
        [self->mROISelect removeAllItems];
        [self->mROISelect addItemWithTitle:DEFAULT_ROI_TEXT];
    } else {
        [self->mROISelect removeItemWithTitle:label];
    }
    
    [self updateViewStates];
}

-(EDDataElement*)roiAsBinaryMask:(NSString*)roiLabel
{
    EDDataElement* maskCache = [self->mROIMasks valueForKey:roiLabel];
    return [[self->mROISelections valueForKey:roiLabel] addToBinaryMask:maskCache];
}

-(BOOL)isCompatible:(EDDataElement*)data
               with:(EDDataElement*)other
{
    if (data == nil || other == nil) {
        return data == nil && other == nil;
    }
    
    enum ImageOrientation dOrient = [data  getMainOrientation];
    enum ImageOrientation oOrient = [other getMainOrientation];
    
    BARTImageSize* dSize = [data getImageSize];
    BARTImageSize* oSize = [other getImageSize];
    
    // TODO: compare voxel size+spacing, row and col vector too!
    
    return dOrient       == oOrient
        && dSize.columns == oSize.columns
        && dSize.rows    == oSize.rows
        && dSize.slices  == oSize.slices;
}

-(BAROISelection*)makeSelectionFrom:(EDDataElement*)data
                                 at:(BADataVoxel*)clickPoint
                            inRange:(float)min
                                and:(float)max;
{
    BAROISelection* selection = nil;
    long toolIndex = [self->mToolSelect selectedSegment];
    if (toolIndex == 0) {
        // PointRange ("MagicCluster")
        selection = [[BAROIPointRangeSelection alloc] initWithReference:data
                                                                  point:clickPoint
                                                                   mode:self->mMode
                                                                inRange:min
                                                                    and:max];
    }
    
    return selection;
}

// ############################
// # Protocol implementations #
// ############################

-(void)clickOn:(EDDataElement*)data at:(BADataVoxel*)p
{
    NSLog(@"ROIController received click at: %@. No range given. Ignoring", p);
}

-(void)clickOn:(EDDataElement*)data
            at:(BADataVoxel*)p
       inRange:(float)min
           and:(float)max
{
    if (data != nil && p != nil && [self->mROISelections count] > 0) {
        NSString* currentROI = [[self->mROISelect selectedItem] title];
        NSLog(@"selected ROI: %@", currentROI);
        
        EDDataElement* currentMask = [self->mROIMasks valueForKey:currentROI];
        if (![self isCompatible:currentMask with:data]) {
            BARTImageSize* maskSize = [data getImageSize];
            maskSize.timesteps = 1;
            EDDataElement* newMask = [[EDDataElement alloc] initEmptyWithSize:maskSize
                                                                  ofImageType:data.mImageType
                                                          withOrientationFrom:data];
            
            [self->mROIMasks setValue:newMask forKey:currentROI];
            
            // Small hack: before setting the mask to the renderer
            // Set one value to 1.0 so (min, max) is (0.0, 1.0) instead of (0.0, 0.0)
            // The renderer only checks for (min, max) once: when the data is set
            // If (min, max) change later due to changes to the data, it is not recognized!
            [newMask setVoxelValue:[NSNumber numberWithFloat:1.0f] atRow:0 col:0 slice:0 timestep:0];
            NSLog(@"MinMax mask: %@", [newMask getMinMaxOfDataElement]);
            [self->mROISelectionRenderer setData:newMask];
            [newMask setVoxelValue:[NSNumber numberWithFloat:0.0f] atRow:0 col:0 slice:0 timestep:0]; // revert
            
            NSLog(@"data orient: %d, mask orient: %d", [data getMainOrientation], [newMask getMainOrientation]);
            currentMask = newMask;
            
            [newMask release];
        }
        
        BAROISelection* selection = [self makeSelectionFrom:data at:p inRange:min and:max];
        if (selection != nil) {
            BAROISelection* parentSelection = [self->mROISelections valueForKey:currentROI];
            [parentSelection addChild:selection];
            NSLog(@"Current ROI (%@) selection: %@", currentROI, selection);
            [selection addToBinaryMask:currentMask];
            [selection release];
        }
        
        // Force rerender since original DataElement has changed
        [self->mROISelectionRenderer renderImage:YES];
    }
}

@end

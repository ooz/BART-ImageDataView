//
//  BAROIController.m
//  ImageDataView
//
//  Created by Oliver Zscheyge on 4/18/13.
//
//

#import "BAROIController.h"
#import "EDDataElement.h"
#import "BADataVoxel.h"
#import "BAROIPointThresholdSelection.h"


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

/** Creates a BAROISelection object from the given parameters and 
 *  the current view state.
 *
 * \param data       EDDataElement defining the image space
 * \param clickPoint 4D point that was clicked within the parameter data.
 * \return           BAROISelection taking both given paraemters and the 
 *                   current view state into account.
 */
-(BAROISelection*)makeSelectionFrom:(EDDataElement*)data
                                and:(BADataVoxel*)clickPoint;

@end


// ##################
// # Implementation #
// ##################

@implementation BAROIController

@synthesize mToolSelect;
@synthesize mModeSelect;
@synthesize mROISelect;

@synthesize mThresholdField;
@synthesize mThresholdStepper;

-(id)init
{
    if (self = [super initWithNibName:@"BAROIToolboxView" bundle:nil]) {
        self->mROIs = [[NSMutableDictionary alloc] init];
        self->mMode = ADD;
        self->mThreshold = 0.0f;
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
    [self->mROIs release];
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
    
}

-(IBAction)setThreshold:(id)sender
{
    
}

-(void)updateViewStates
{
    if ([self->mROIs count] == 0) {
        [self->mROISelect setEnabled:NO];
        [self->mToolSelect setEnabled:NO];
        [self->mModeSelect setEnabled:NO];
        [self->mThresholdField setEnabled:NO];
        [self->mThresholdStepper setEnabled:NO];
    } else {
        [self->mROISelect setEnabled:YES];
        [self->mToolSelect setEnabled:YES];
        [self->mModeSelect setEnabled:YES];
        [self->mThresholdField setEnabled:YES];
        [self->mThresholdStepper setEnabled:YES];
    }
    
    NSLog(@"ROIs: %@", self->mROIs);
}


// ###################
// # Regular methods #
// ###################

-(void)addROI:(NSString*)label
{
    if (label != nil) {
        if ([self->mROIs count] == 0) {
            [self->mROISelect removeAllItems];
        }
        
        BAROISelection* roiSelection = [[BAROISelection alloc] init];
        [self->mROIs setValue:roiSelection forKey:label];
        [self->mROISelect addItemWithTitle:label];
        [roiSelection release];
        
        [self updateViewStates];
    }    
}

-(void)removeROI:(NSString*)label
{
    [self->mROIs removeObjectForKey:label];
    
    if ([self->mROIs count] == 0) {
        [self->mROISelect removeAllItems];
        [self->mROISelect addItemWithTitle:DEFAULT_ROI_TEXT];
    } else {
        [self->mROISelect removeItemWithTitle:label];
    }
    
    [self updateViewStates];
}

-(EDDataElement*)roiAsBinaryMask:(NSString*)roiLabel
{
    BAROISelection* sel = [self->mROIs valueForKey:roiLabel];
    if (sel != nil) {
        return [sel asBinaryMask];
    }
    
    return nil;
}

-(BAROISelection*)makeSelectionFrom:(EDDataElement*)data
                                and:(BADataVoxel*)clickPoint
{
    BAROISelection* selection = nil;
    long toolIndex = [self->mToolSelect selectedSegment];
    if (toolIndex == 0) {
        // PointThreshold
        selection = [[BAROIPointThresholdSelection alloc] initWithReference:data
                                                                      point:clickPoint
                                                                       mode:self->mMode
                                                               andThreshold:nil]; // TODO: pass proper threshold!
    }
    
    return selection;
}

// ############################
// # Protocol implementations #
// ############################

-(void)clickOn:(EDDataElement*)data at:(BADataVoxel*)p
{
    NSLog(@"ROIController received click: %@", p);
    
    if (data != nil && [self->mROIs count] > 0) {
        NSString* currentROI = [[self->mROISelect selectedItem] title];
        NSLog(@"selected ROI: %@", currentROI);
        [data setVoxelValue:[NSNumber numberWithFloat:1300.0]
                      atRow:p.row
                        col:p.column
                      slice:p.slice
                   timestep:p.timestep];
        
        BAROISelection* selection = [self makeSelectionFrom:data and:p];
        if (selection != nil) {
            BAROISelection* parentSelection = [self->mROIs valueForKey:currentROI];
            [parentSelection addChild:selection];
            [selection release];
        }
    }
}

@end

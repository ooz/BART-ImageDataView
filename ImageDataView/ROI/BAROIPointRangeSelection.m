//
//  BAROIPointRangeSelection.m
//  ImageDataView
//
//  Created by Oliver Z. on 5/14/13.
//
//

#import "BAROIPointRangeSelection.h"
#import "BADataVoxel.h"

@implementation BAROIPointRangeSelection

@synthesize max = mMax;

-(id)initWithReference:(EDDataElement*)data
                 point:(BADataVoxel*)p
                  mode:(enum ROISelectionMode)m
               inRange:(float)min
                   and:(float)max
{
    if (self = [super initWithReference:data
                                  point:p
                                   mode:m
                           andThreshold:min]) {
        self->mMax = max;
    }
    
    return self;
}

-(void)dealloc
{
    [super dealloc];
}

-(EDDataElement*)addToBinaryMask:(EDDataElement*)mask
{
    float value = (self->mMode == ADD) ? 1.0f : 0.0f;
    if (mask != nil) {
        BARTImageSize* refSize  = [self->mReference getImageSize];
        BARTImageSize* maskSize = [mask getImageSize];
        NSMutableArray* stack = [[NSMutableArray alloc] initWithCapacity:64];
        [stack addObject:self->mPoint];
        while ([stack count] > 0) {
            BADataVoxel* p = [[stack lastObject] retain];
            [stack removeLastObject];
            
            if (p.column < refSize.columns && p.column < maskSize.columns
                && p.row < refSize.rows && p.row < maskSize.rows
                && p.slice < refSize.slices && p.slice < maskSize.rows
                && p.timestep < refSize.timesteps && p.timestep < maskSize.timesteps) {
                float refVal = [self->mReference getFloatVoxelValueAtRow:p.row
                                                                     col:p.column
                                                                   slice:p.slice
                                                                timestep:p.timestep];
                float maskVal = [mask getFloatVoxelValueAtRow:p.row
                                                          col:p.column
                                                        slice:p.slice
                                                     timestep:p.timestep];
                if (refVal >= self->mThreshold && refVal <= self->mMax && maskVal != value) {
                    [mask setVoxelValue:[NSNumber numberWithFloat:value]
                                  atRow:p.row
                                    col:p.column
                                  slice:p.slice
                               timestep:p.timestep];
                    BADataVoxel* newP;
                    newP = [[BADataVoxel alloc] initWithColumn:p.column + 1
                                                           row:p.row
                                                         slice:p.slice
                                                      timestep:p.timestep];
                    [stack addObject:newP];
                    [newP release];
                    newP = [[BADataVoxel alloc] initWithColumn:p.column - 1
                                                           row:p.row
                                                         slice:p.slice
                                                      timestep:p.timestep];
                    [stack addObject:newP];
                    [newP release];
                    newP = [[BADataVoxel alloc] initWithColumn:p.column
                                                           row:p.row + 1
                                                         slice:p.slice
                                                      timestep:p.timestep];
                    [stack addObject:newP];
                    [newP release];
                    newP = [[BADataVoxel alloc] initWithColumn:p.column
                                                           row:p.row - 1
                                                         slice:p.slice
                                                      timestep:p.timestep];
                    [stack addObject:newP];
                    [newP release];
                    newP = [[BADataVoxel alloc] initWithColumn:p.column
                                                           row:p.row
                                                         slice:p.slice + 1
                                                      timestep:p.timestep];
                    [stack addObject:newP];
                    [newP release];
                    newP = [[BADataVoxel alloc] initWithColumn:p.column
                                                           row:p.row
                                                         slice:p.slice - 1
                                                      timestep:p.timestep];
                    [stack addObject:newP];
                    [newP release];
                }
                [p release];
            }
        }
        [stack release];
    }
    
    for (BAROISelection* sel in self->mChildren) {
        mask = [sel addToBinaryMask:mask];
    }
    return mask;
}


-(NSString*)description {
    return [NSString stringWithFormat:@"BAROIPointRangeSelection(point=%@, min=%f, max=%f)", self->mPoint, self->mThreshold, self->mMax];
}

@end

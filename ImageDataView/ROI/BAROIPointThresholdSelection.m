//
//  BAROIPointThresholdSelection.m
//  ImageDataView
//
//  Created by Oliver Z. on 3/19/13.
//
//

#import "BAROIPointThresholdSelection.h"
#import "BADataVoxel.h"

static const enum ImageOrientation DEFAULT_ORIENTATION = ORIENT_AXIAL;

@implementation BAROIPointThresholdSelection

@synthesize point = mPoint;
@synthesize threshold = mThreshold;


-(id)initWithReference:(EDDataElement*)data
                 point:(BADataVoxel*)p
                  mode:(enum ROISelectionMode)m
          andThreshold:(float)thres;
{
    if (self = [super initWithMode:m]) {
        self->mReference = [data retain];
        self->mPoint     = [p retain];
        self->mThreshold = thres;
    }
    
    return self;
}

-(void)dealloc
{
    [self->mReference release];
    
    [self->mPoint release];
    self->mPoint = nil;
    
    [super dealloc];
}

-(EDDataElement*)asBinaryMask
{
    BARTImageSize* referenceSize = [self->mReference getImageSize];
    BARTImageSize* maskSize = [[BARTImageSize alloc] initWithRows:referenceSize.rows
                                                          andCols:referenceSize.columns
                                                        andSlices:referenceSize.slices
                                                     andTimesteps:1];
    EDDataElement* mask = [[[EDDataElement alloc] initEmptyWithSize:maskSize
                                                        ofImageType:[self->mReference getImageDataType]
                                                withOrientationFrom:self->mReference] autorelease];
    
    [maskSize release];
    
    mask = [self addToBinaryMask:mask];
    
    return mask;
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
                if (refVal >= self->mThreshold && maskVal != value) {
//                    NSLog(@"Set point: %@", p);
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
    
    [super addToBinaryMask:mask];
    return mask;
}

-(NSString*)description {
    return [NSString stringWithFormat:@"BAROIPointThresholdSelection(point=%@, thres=%f)", self->mPoint, self->mThreshold];
}

@end

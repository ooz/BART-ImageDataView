//
//  BAROIPointThresholdSelection.m
//  ImageDataView
//
//  Created by Oliver Zscheyge on 3/19/13.
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
          andThreshold:(NSNumber*)thres;
{
    if (self = [super initWithMode:m]) {
        self->mReference = [data retain];
        self->mPoint     = [p retain];
        self->mThreshold = [thres retain];
    }
    
    return self;
}

-(void)dealloc
{
    [self->mReference release];
    
    [self->mPoint release];
    self->mPoint = nil;
    
    [self->mThreshold release];
    self->mThreshold = nil;
    
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
                                                        ofImageType:[self->mReference getImageDataType]] autorelease];
    
    [maskSize release];
    
    mask = [self addToBinaryMask:mask];
    
    return mask;
}

-(EDDataElement*)addToBinaryMask:(EDDataElement*)mask
{
    float value = (self->mMode == ADD) ? 1.0f : 0.0f;
    if (mask != nil) {
        [mask setVoxelValue:[NSNumber numberWithFloat:value]
                      atRow:self->mPoint.row
                        col:self->mPoint.column
                      slice:self->mPoint.slice
                   timestep:self->mPoint.timestep];
    }
    
    [super addToBinaryMask:mask];
    return mask;
}

@end

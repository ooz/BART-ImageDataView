//
//  BAROIPointThresholdSelection.m
//  ImageDataView
//
//  Created by Oliver Zscheyge on 3/19/13.
//
//

#import "BAROIPointThresholdSelection.h"

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

@end

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


-(id)initWithPoint:(BADataVoxel*)p andThreshold:(NSNumber*)thres
{
    if (self = [super init]) {
        self->mPoint     = [p retain];
        self->mThreshold = [thres retain];
    }
    
    return self;
}

-(void)dealloc
{
    [self->mPoint release];
    self->mPoint = nil;
    
    [self->mThreshold release];
    self->mThreshold = nil;
    
    [super dealloc];
}

@end

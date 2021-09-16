//
//  BAROIPointSetSelection.m
//  ImageDataView
//
//  Created by Oliver Z. on 3/19/13.
//
//

#import "BAROIPointSetSelection.h"

@implementation BAROIPointSetSelection

@synthesize points = mPoints;

-(id)initWithPoints:(NSArray*)points
{
    if (self = [super init]) {
        self->mPoints = [points retain];
    }
    
    return self;
}

-(void)dealloc
{
    [self->mPoints release];
    self->mPoints = nil;
    
    [super dealloc];
}

@end

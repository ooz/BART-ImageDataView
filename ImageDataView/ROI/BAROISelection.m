//
//  BAROISelection.m
//  ImageDataView
//
//  Created by Oliver Zscheyge on 3/19/13.
//
//

#import "BAROISelection.h"

@interface BAROISelection (PrivateMutators)

@property (assign) BAROISelection* parent;

@end



@implementation BAROISelection

@synthesize parent = mParent;


-(id)init
{
    if (self = [super init]) {
        self->mMode   = ADD;
        self->mParent = nil;
        self->mChildren = [[NSMutableArray alloc] init];
    }
    
    return self;
}

-(id)initWithMode:(enum ROISelectionMode)m
{
    if (self = [self init]) {
        self->mMode = m;
    }
    
    return self;
}

-(void)dealloc
{
    self->mParent = nil;
    [self->mChildren release];
    
    [super dealloc];
}

-(enum ROISelectionMode)mode
{
    return self->mMode;
}

-(NSArray*)children
{
    return [NSArray arrayWithArray:self->mChildren];
}

-(void)addChild:(BAROISelection*)child
{
    [self->mChildren addObject:child];
    child.parent = self;
}

-(void)removeChild:(BAROISelection*)child
{
    [self->mChildren removeObject:child];
    child.parent = nil;
}


-(EDDataElement*)asBinaryMask
{
    return nil;
}

-(EDDataElement*)addToBinaryMask:(EDDataElement*)mask
{
    return mask;
}

//-(NSArray*)asPointSet
//{
//    return [NSArray array];
//}

@end

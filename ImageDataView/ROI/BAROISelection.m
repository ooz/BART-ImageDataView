//
//  BAROISelection.m
//  ImageDataView
//
//  Created by Oliver Z. on 3/19/13.
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
    child->mParent = self;
}

-(void)removeChild:(BAROISelection*)child
{
    [self->mChildren removeObject:child];
    child->mParent = nil;
}


//-(EDDataElement*)asBinaryMask
//{
//    if ([self->mChildren count] > 0) {
//        EDDataElement* mask = [[self->mChildren objectAtIndex:0] asBinaryMask];
//        
//        for (NSUInteger i = 1; i < [self->mChildren count]; i++) {
//            mask = [[self->mChildren objectAtIndex:i] addToBinaryMask:mask];
//        }
//        
//        return mask;
//    }
//    
//    return nil;
//}

-(EDDataElement*)addToBinaryMask:(EDDataElement*)mask
{
    for (BAROISelection* sel in self->mChildren) {
        mask = [sel addToBinaryMask:mask];
    }
    return mask;
}

-(NSString*)description {
    return [NSString stringWithFormat: @"BAROISelection(parent=%@, #children=%ld)", self->mParent, [self->mChildren count]];
}

//-(NSArray*)asPointSet
//{
//    return [NSArray array];
//}

@end

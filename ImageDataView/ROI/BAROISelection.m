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
-(void)setLabel:(NSString*)label;

@end



@implementation BAROISelection

@synthesize parent = mParent;


-(id)init
{
    if (self = [super init]) {
        self->mLabel  = nil;
        self->mParent = nil;
        self->mChildren = [[NSMutableArray alloc] init];
    }
    
    return self;
}

-(void)dealloc
{
    self->mParent = nil;
    self.label = nil;
    [self->mChildren release];
    
    [super dealloc];
}


-(NSString*)label
{
    if (self->mLabel == nil && self.parent != nil) {
        return self.parent.label;
    }
    
    return self->mLabel;
}

-(void)setLabel:(NSString*)label
{
    [label retain];
    [self->mLabel release];
    self->mLabel = label;
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

-(NSArray*)asPointSet
{
    return nil;
}

@end

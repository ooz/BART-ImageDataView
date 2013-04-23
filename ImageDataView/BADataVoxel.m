//
//  BADataVoxel.m
//  ImageDataView
//
//  Created by Oliver Zscheyge on 4/23/13.
//
//

#import "BADataVoxel.h"

@implementation BADataVoxel

@synthesize column;
@synthesize row;
@synthesize slice;
@synthesize timestep;

-(id)init
{
    if (self = [super init]) {
        self->column   = 0;
        self->row      = 0;
        self->slice    = 0;
        self->timestep = 0;
    }
    
    return self;
}

-(id)initWithColumn:(NSUInteger)c
                row:(NSUInteger)r
              slice:(NSUInteger)s
           timestep:(NSUInteger)ts
{
    if (self = [super init]) {
        self->column   = c;
        self->row      = r;
        self->slice    = s;
        self->timestep = ts;
    }
    
    return self;
}

-(NSString*)description {
    return [NSString stringWithFormat: @"BADataVoxel(col=%ld, row=%ld, slice=%ld, ts=%ld)",
            self->column, self->row, self->slice, self->timestep];
}

@end

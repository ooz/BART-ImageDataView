//
//  BADataVoxel.m
//  ImageDataView
//
//  Created by Oliver Z. on 4/23/13.
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

-(void)convertFrom:(enum ImageOrientation)srcOrient
                to:(enum ImageOrientation)tarOrient
{
    BOOL isSagittal = srcOrient == ORIENT_SAGITTAL || srcOrient == ORIENT_REVSAGITTAL;
    BOOL isAxial    = srcOrient == ORIENT_AXIAL    || srcOrient == ORIENT_REVAXIAL;
    BOOL isCoronal  = srcOrient == ORIENT_CORONAL  || srcOrient == ORIENT_REVCORONAL;
    
    BOOL targetSagittal = tarOrient == ORIENT_SAGITTAL || tarOrient == ORIENT_REVSAGITTAL;
    BOOL targetAxial    = tarOrient == ORIENT_AXIAL    || tarOrient == ORIENT_REVAXIAL;
    BOOL targetCoronal  = tarOrient == ORIENT_CORONAL  || tarOrient == ORIENT_REVCORONAL;
    
    NSUInteger swap = self->column;
    if (isSagittal && targetAxial) {
        self->column = self->slice;
        self->slice = self->row;
        self->row = swap;
        
    } else if ((isSagittal && targetCoronal)
               || (isCoronal && targetSagittal)) {
        self->column = self->slice;
        self->slice = swap;
        
    } else if (isAxial && targetSagittal) {
        self->column = self->row;
        self->row = self->slice;
        self->slice = swap;
        
    } else if ((isAxial && targetCoronal)
               || (isCoronal && targetAxial)) {
        swap = self->row;
        self->row = self->slice;
        self->slice = swap;
    }
}

-(id)createVoxelByConvertingFrom:(enum ImageOrientation)srcOrient
                              to:(enum ImageOrientation)tarOrient
{
    BADataVoxel* newVoxel = [[BADataVoxel alloc] initWithColumn:self->column
                                                            row:self->row
                                                          slice:self->slice
                                                       timestep:self->timestep];
    [newVoxel convertFrom:srcOrient to:tarOrient];
    return newVoxel;
}

-(NSString*)description {
    return [NSString stringWithFormat: @"BADataVoxel(col=%ld, row=%ld, slice=%ld, ts=%ld)",
            self->column, self->row, self->slice, self->timestep];
}

@end

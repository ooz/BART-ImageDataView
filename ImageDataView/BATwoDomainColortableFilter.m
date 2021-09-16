//
//  BATwoDomainColortableFilter.m
//  ImageDataView
//
//  Created by Oliver Z. on 10/18/12.
//  Copyright (c) 2012 MPI CBS. All rights reserved.
//

#import "BATwoDomainColortableFilter.h"

#import "ColorMappingFilter.h"
#import "BAImageDataViewConstants.h"

extern CIFormat kCIFormatRGBAf;

@implementation BATwoDomainColortableFilter

-(id)init
{
    if (self = [super init]) {
    }
    
    return self;
}

-(void)dealloc
{
    [super dealloc];
}

-(CIImage*)apply:(CIImage*)on
{
    [ColorMappingFilter class];
    
    self->mFilter = [CIFilter filterWithName: @"ColorMappingFilterTwoDomains"
                               keysAndValues: @"inputImage", on,
                                              @"colorTable", self->mColortable, nil];
    
    int colortableMappingType = 3;
    [(ColorMappingFilter*) self->mFilter setKernelToUse: colortableMappingType];
    
    //    float    filterMinimum = 0.0;
    //    float    filterMaximum = 255.0;
    [self->mFilter setValue: [self valueForKey:@"minimum"]
                     forKey: @"minimum"];
    [self->mFilter setValue: [self valueForKey:@"maximum"]
                     forKey: @"maximum"];
    [self->mFilter setValue: [self valueForKey:@"minimum2"]
                     forKey: @"minimum2"];
    [self->mFilter setValue: [self valueForKey:@"maximum2"]
                     forKey: @"maximum2"];
    
    return [self->mFilter valueForKey:@"outputImage"];
}


@end

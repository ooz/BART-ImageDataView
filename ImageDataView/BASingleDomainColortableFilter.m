//
//  BASingleDomainColortableFilter.m
//  ImageDataView
//
//  Created by Oliver Z. on 9/14/12.
//  Copyright (c) 2012 MPI CBS. All rights reserved.
//

#import "BASingleDomainColortableFilter.h"

#import "ColorMappingFilter.h"
#import "BAImageDataViewConstants.h"

extern CIFormat kCIFormatRGBAf;

@implementation BASingleDomainColortableFilter

-(id)init
{
    if (self = [super init]) {
        self->mColortable = nil;
        
        [self setValue:[NSNumber numberWithFloat:0.0f] forKey:@"minimum"];
        [self setValue:[NSNumber numberWithFloat:1.0f] forKey:@"maximum"];
        
        NSSize ctSize;
        ctSize.width  = 512;
        ctSize.height = 1;
        
        //float colorTableData[256 * 4 * 2];
        float* colorTableData = malloc(sizeof(float) * 256 * 4 * 2);
        
        // red to yellow (the more positive the more yellow)
        for(int _ctIndex = 0; _ctIndex < 256; _ctIndex++) {
            colorTableData[_ctIndex * 4 + 0] = 1.0;
            colorTableData[_ctIndex * 4 + 1] = 1.0 * (_ctIndex / 255.0);
            colorTableData[_ctIndex * 4 + 2] = 0.0;//1.0 * _ctIndex / 255.0;
            colorTableData[_ctIndex * 4 + 3] = 1.0;
        }
        // cyan to blue (the more negative the more cyan)
        for(int _ctIndex = 0; _ctIndex < 256; _ctIndex++) {
            colorTableData[(_ctIndex + 256) * 4 + 0] = 0.0;//0.5 - 0.5 * (_ctIndex / 255.0); // 127 to 0
            colorTableData[(_ctIndex + 256) * 4 + 1] = 1.0 * (_ctIndex / 255.0); // 255 to 0
            colorTableData[(_ctIndex + 256) * 4 + 2] = 1.0;//1.0 * (_ctIndex / 255.0);
            colorTableData[(_ctIndex + 256) * 4 + 3] = 1.0;
        }
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        self->mColortable = [[CIImage alloc] initWithBitmapData:[NSData dataWithBytes:colorTableData length:512 * sizeof(float) * NUMBER_OF_CHANNELS]
                                                    bytesPerRow:512 * sizeof(float) * NUMBER_OF_CHANNELS
                                                           size:ctSize 
                                                         format:kCIFormatRGBAf 
                                                     colorSpace:colorSpace];
        
        CGColorSpaceRelease(colorSpace);
        free(colorTableData);

        
    }
    
    return self;
}

-(void)dealloc
{
    if (self->mColortable != nil) 
        [self->mColortable release];
    
    [super dealloc];
}

-(CIImage*)apply:(CIImage*)on
{
    [ColorMappingFilter class];
        
    self->mFilter = [CIFilter filterWithName: @"ColorMappingFilter"
                               keysAndValues: @"inputImage", on,
                                              @"colorTable", self->mColortable, nil];
    
    int colortableMappingType = 2;
    [(ColorMappingFilter*) self->mFilter setKernelToUse: colortableMappingType];
    
//    float    filterMinimum = 0.0;
//    float    filterMaximum = 255.0;
    [self->mFilter setValue: [self valueForKey:@"minimum"]
                          forKey: @"minimum"];
    [self->mFilter setValue: [self valueForKey:@"maximum"]
                          forKey: @"maximum"];
    
    return [self->mFilter valueForKey:@"outputImage"];
}

@end

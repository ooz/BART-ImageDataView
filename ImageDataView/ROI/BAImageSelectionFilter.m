//
//  BAImageSelectionFilter.m
//  ImageDataView
//
//  Created by Oliver Zscheyge on 4/11/13.
//
//

#import "BAImageSelectionFilter.h"

#import "ColorMappingFilter.h"
#import "BAImageDataViewConstants.h"

extern CIFormat kCIFormatRGBAf;

@implementation BAImageSelectionFilter

-(id)init
{
    if (self = [super init]) {
        [self setValue:[NSNumber numberWithFloat:0.0f] forKey:@"minimum"];
        [self setValue:[NSNumber numberWithFloat:1.0f] forKey:@"maximum"];
        
        NSSize ctSize;
        ctSize.width  = 2;
        ctSize.height = 1;
        
        //float colorTableData[256 * 4 * 2];
        float* colorTableData = malloc(sizeof(float) * 4 * 2);
        
        // fully transparent, not selected
        int i = 0;
        colorTableData[i + 0] = 0.0;
        colorTableData[i + 1] = 0.0;
        colorTableData[i + 2] = 0.0;
        colorTableData[i + 3] = 0.0;
        i++;
        // slightly transparent green, selected
        colorTableData[i + 0] = 0.0;
        colorTableData[i + 1] = 1.0;
        colorTableData[i + 2] = 0.0;
        colorTableData[i + 3] = 0.5;
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        [self->mColortable release];
        self->mColortable = [[CIImage alloc] initWithBitmapData:[NSData dataWithBytes:colorTableData length:2 * sizeof(float) * NUMBER_OF_CHANNELS]
                                                    bytesPerRow:2 * sizeof(float) * NUMBER_OF_CHANNELS
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
    [super dealloc];
}

@end

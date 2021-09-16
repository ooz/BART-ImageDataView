//
//  ColorMappingFilterTwoDomains.m
//  ImageDataView
//
//  Created by Oliver Z. on 10/18/12.
//  Copyright (c) 2012 MPI CBS. All rights reserved.
//

#import "ColorMappingFilterTwoDomains.h"

#import <QuartzCore/CIKernel.h>
#import <QuartzCore/CISampler.h>
#import <Foundation/NSString.h>

@implementation ColorMappingFilterTwoDomains

static NSArray* colorMappingFilterKernels = nil;

@synthesize kernelToUse;

// this method is called by [ColorMappingFilter class] to register our filter with the CIFilter class
+(void)initialize {
    [CIFilter registerFilterName: @"ColorMappingFilterTwoDomains"
					 constructor: self
				 classAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
								   @"Color Mapping", kCIAttributeFilterDisplayName,
								   [NSArray arrayWithObjects:
									kCICategoryColorAdjustment, kCICategoryVideo,
									kCICategoryStillImage,kCICategoryInterlaced,
									kCICategoryNonSquarePixels,nil], kCIAttributeFilterCategories,
								   nil]];
}

// this (static) method returns an instance of our filter
+(CIFilter*)filterWithName:(NSString*)name {
    CIFilter* filter = [[self alloc] init];
    
    return [filter autorelease];
}

// the init() method initializes our kernel(s) with the actual kernel code from the .cikernel file
-(id)init
{
    if (self = [super init]) {
        if(colorMappingFilterKernels == nil) {
            
            //        NSString* code    = [NSString stringWithContentsOfFile:@"/Users/user/Development/BARTProcedure/BARTApplication/ColorMappingFilter.cikernel"
            //													  encoding: NSUTF8StringEncoding
            //                                                         error:NULL];
            
            NSBundle* bundle  = [NSBundle bundleForClass: [self class]];
            NSString* code    = [NSString stringWithContentsOfFile: [bundle pathForResource: @"ColorMappingFilter"
                                                                                     ofType: @"cikernel"]
                                                          encoding: NSUTF8StringEncoding
                                                             error: NULL];
            
            NSArray*  kernels = [CIKernel kernelsWithString: code];
//            NSLog(@"###In Array: %lu",[kernels count]);
            // if the .cikernel file contains more then one kernel we would end up
            // with an array of kernels
            
            // the 'copyItems:NO' simply sends a 'retain' to all array elements, so we need
            // a 'release' somewhere !?!?!?!?!?
            colorMappingFilterKernels = [[NSArray alloc] initWithArray:kernels copyItems:NO];
            
        }
        
        self->kernelToUse = 3;
        
    }
    
    return self;
}

-(CIImage*)outputImage
{
    CISampler* src = [CISampler samplerWithImage: inputImage];
    CISampler* colTable = [CISampler samplerWithImage: colorTable];
	CIImage *ret = [self apply: [colorMappingFilterKernels objectAtIndex:kernelToUse], src, colTable, minimum, maximum, minimum2, maximum2, kCIApplyOptionDefinition, [src definition], nil];
	
	return ret;
}

-(void)dealloc
{
	[inputImage release];
	[colorTable release];
    [minimum release];
    [maximum release];
    [minimum2 release];
    [maximum2 release];
    
	[super dealloc];
}

@end

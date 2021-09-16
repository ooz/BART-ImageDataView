//
//  ColorMappingFilterTwoDomains.h
//  ImageDataView
//
//  Created by Oliver Z. on 10/18/12.
//  Copyright (c) 2012 MPI CBS. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <QuartzCore/CIFilter.h>

/**
 * Custom CIFilter for use with colortables (supporting 2 domains).
 */
@interface ColorMappingFilterTwoDomains : CIFilter {
    
    /** Image to apply the filter to. */
	CIImage*  inputImage;
    
    /** Image representing the colortable.
     * Usually based on a n-dimensional data vector where n is the number of colors.
     */
	CIImage*  colorTable;
    
    /** Minimum color value of the 1st domain that will be mapped to the "lowest" color of the colortable. */
	NSNumber* minimum;
    /** Maximum color value of the 1st domain that will be mapped to the "highest" color of the colortable. */
	NSNumber* maximum;
    
    /** Minimum color value of the 2nd domain that will be mapped to the "lowest" color of the colortable. */
	NSNumber* minimum2;
    /** Maximum color value of the 2nd domain that will be mapped to the "highest" color of the colortable. */
	NSNumber* maximum2;
    
}

/** Kernel function to apply to each pixel of a CIImage.
 * Custom CIKernels are defined in a different file. 
 * They are loaded dynamically at runtime and indexed based on their occurence in said file
 * (starting with index 0). */
@property int kernelToUse;

@end

//
//  ColorMappingFilterOne.h
//  CIFilter Test 001
//
//  Created by Torsten Schlumm on 12/23/09.
//  Documentation by Oliver Z. on 10/12/2012.
//  Copyright 2009 MPI CBS. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <QuartzCore/CIFilter.h>

/**
 * Custom CIFilter for use with colortables.
 */
@interface ColorMappingFilter : CIFilter {
	
    /** Image to apply the filter to. */
	CIImage*  inputImage;
    
    /** Image representing the colortable.
     * Usually based on a n-dimensional data vector where n is the number of colors.
     */
	CIImage*  colorTable;
    
    /** Minimum color value that will be mapped to the "lowest" color of the colortable. */
	NSNumber* minimum;
    /** Maximum color value that will be mapped to the "highest" color of the colortable. */
	NSNumber* maximum;

}

/** Kernel function to apply to each pixel of a CIImage.
 * Custom CIKernels are defined in a different file. 
 * They are loaded dynamically at runtime and indexed based on their occurence in said file
 * (starting with index 0). */
@property int kernelToUse;

@end

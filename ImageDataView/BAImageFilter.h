//
//  BAImageFilter.h
//  ImageDataView
//
//  Created by Oliver Z. on 9/14/12.
//  Copyright (c) 2012 MPI CBS. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Common superclass for colortable based image filters.
 * This class is not meant for direct use but for subclassing.
 */
@interface BAImageFilter : NSObject {
    
    /** Wrapped CIFilter. */
    CIFilter* mFilter;
    
    /** Custom parameter map passed to mFilter. */
    NSMutableDictionary* mParams;
    
}

/** Getter. */
-(CIFilter*)filter;

/**
 * Applies the wrapped CIFilter to a CIImage object.
 *
 * \param on CIImage to apply the filter to.
 * \return   New CIImage resulting from applying the filter
 *           on the passed image.
 */
-(CIImage*)apply:(CIImage*)on;

/**
 * Sets a named parameter.
 */
-(void)setValue:(id)value forKey:(NSString *)key;

/**
 * Gets a named parameter.
 */
-(id)valueForKey:(NSString *)key;

@end

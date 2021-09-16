//
//  BASingleDomainColortableFilter.h
//  ImageDataView
//
//  Created by Oliver Z. on 9/14/12.
//  Copyright (c) 2012 MPI CBS. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BAImageFilter.h"

/** Colortable filter with a single domain (region). */
@interface BASingleDomainColortableFilter : BAImageFilter {
    
    /** CIImage representing the colortable to use.
     * Usually n-dimensional color value vector where n is the number of colors 
     * in the colortable. */
    CIImage* mColortable;
    
}

@end

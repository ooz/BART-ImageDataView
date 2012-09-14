//
//  BASingleDomainColortableFilter.h
//  ImageDataView
//
//  Created by Oliver Zscheyge on 9/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BAImageFilter.h"

@interface BASingleDomainColortableFilter : BAImageFilter {
    
    CIImage* mColortable;
    
}

@end

//
//  BAImageSliceSelector.h
//  ImageDataView
//
//  Created by Oliver Zscheyge on 7/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EDDataElement.h"

@interface BAImageSliceSelector : NSObject

-(NSArray*)select:(size_t)n 
       slicesFrom:(EDDataElement*)image
        alignedTo:(enum ImageOrientation)orientation;

@end

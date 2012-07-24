//
//  BAImageSliceSelector.h
//  ImageDataView
//
//  Created by Oliver Zscheyge on 7/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EDDataElement;

@interface BAImageSliceSelector : NSObject

-(NSArray*)select:(size_t)n slicesFrom:(EDDataElement*)image;

@end

//
//  BADataElementRenderer.h
//  ImageDataView
//
//  Created by Oliver Zscheyge on 8/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EDDataElement.h"

@class BAImageSliceSelector;

@interface BADataElementRenderer : NSObject {
    
}

-(id)initWithSliceSelector:(BAImageSliceSelector*)selector;


-(void)setData:(EDDataElement*)elem
         slice:(uint)sliceNr
      timestep:(uint)tstep;

-(void)setSlice:(uint)sliceNr;
-(void)setTimestep:(uint)tstep;

-(void)setGridSize:(NSSize)size;
-(void)setTargetOrientation:(enum ImageOrientation)o;

-(NSImage*)renderImage;


@end

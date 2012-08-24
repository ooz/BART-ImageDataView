//
//  BADataElementRenderer.h
//  ImageDataView
//
//  Created by Oliver Zscheyge on 8/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BAImageSliceSelector;
@class EDDataElement;

@interface BADataElementRenderer : NSObject {
    
}

-(id)initWithSliceSelector:(BAImageSliceSelector*)selector;


-(void)setData:(EDDataElement*)elem
         slice:(uint)sliceNr
      timestep:(uint)tstep;

-(void)setSlice:(uint)sliceNr;
-(void)setTimestep:(uint)tstep;

-(void)setGridSize:(NSSize)size;


-(NSImage*)renderSagittalImage;
-(NSImage*)renderAxialImage;
-(NSImage*)renderCoronalImage;


@end

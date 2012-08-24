//
//  BABrainImageView.m
//  ImageDataView
//
//  Created by Oliver Zscheyge on 7/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BABrainImageView.h"

#import "BAImageSliceSelector.h"
#import "BADataElementRenderer.h"

@implementation BABrainImageView

- (id)initWithFrame:(NSRect)frame
{
    if (self = [super initWithFrame:frame]) {
    }
    
    return self;
}

/** Disable interpolation in this NSView subclass. */
- (void)drawRect:(NSRect)dirtyRect
{
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationNone];
    
    [super drawRect:dirtyRect];
}

@end

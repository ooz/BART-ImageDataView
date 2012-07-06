//
//  BABrainImageView.m
//  ImageDataView
//
//  Created by Oliver Zscheyge on 7/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BABrainImageView.h"

@implementation BABrainImageView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationNone];
    
    [super drawRect:dirtyRect];
}

@end

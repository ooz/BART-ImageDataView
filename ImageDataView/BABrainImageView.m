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



@interface BABrainImageView (__privateMethods__)

-(void)updateSetImage;

@end



@implementation BABrainImageView

-(id)initWithFrame:(NSRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self->mBackgroundImage = nil;
        self->mForegroundImage = nil;
    }
    
    return self;
}

-(void)dealloc
{
    if (self->mBackgroundImage != nil) [self->mBackgroundImage release];
    if (self->mForegroundImage != nil) [self->mForegroundImage release];
    
    [super dealloc];
}

/** Disable interpolation in this NSView subclass. */
-(void)drawRect:(NSRect)dirtyRect
{
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationNone];
    
    [super drawRect:dirtyRect];
}

-(void)setBackgroundImage:(NSImage*)newImage
{
    if (self->mBackgroundImage != nil) 
        [self->mBackgroundImage release];
    
    if (newImage != nil)
        self->mBackgroundImage = [newImage retain];
    
    [self updateSetImage];
}

-(void)setForegroundImage:(NSImage*)newImage
{
    if (self->mForegroundImage != nil) 
        [self->mForegroundImage release];
    
    if (newImage != nil)
        self->mForegroundImage = [newImage retain];
    
    [self updateSetImage];
}

-(void)updateSetImage
{
    if (       self->mBackgroundImage != nil && self->mForegroundImage == nil) {
        [self setImage:self->mBackgroundImage];
        
    } else if (self->mBackgroundImage == nil && self->mForegroundImage != nil) {
        [self setImage:self->mForegroundImage];
        
    } else {
        // Both images are set
        // Use NSImage composite
        // http://www.bdunagan.com/2010/01/25/cocoa-tip-nsimage-composites/
        
        [self->mBackgroundImage lockFocus];
        
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationNone];
        [self->mForegroundImage drawInRect:NSMakeRect(0, 0, 
                                                      [self->mBackgroundImage size].width, [self->mBackgroundImage size].height) 
                       fromRect:NSZeroRect 
                      operation:NSCompositeSourceOver 
                       fraction:1.0];
        
        [self->mBackgroundImage unlockFocus];
        
        [self setImage:self->mBackgroundImage];
    }
}

@end

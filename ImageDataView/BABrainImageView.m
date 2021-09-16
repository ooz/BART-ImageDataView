//
//  BABrainImageView.m
//  ImageDataView
//
//  Created by Oliver Z. on 7/6/12.
//  Copyright (c) 2012 MPI CBS. All rights reserved.
//

#import "BABrainImageView.h"

#import "BAImageSliceSelector.h"
#import "BADataElementRenderer.h"



@interface BABrainImageView (__privateMethods__)

/** Method that is called whenever a new back-/foreground is set. 
 * Renders the combined back- plus foreground image. */
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

-(void)setImages:(NSImage*)foreground 
              on:(NSImage*)background
{
    if (self->mForegroundImage != nil) [self->mForegroundImage release];
    
    if (foreground != nil) {
        self->mForegroundImage = [foreground retain];
    } else {
        self->mForegroundImage = nil;
    }
    
    if (self->mBackgroundImage != nil) [self->mBackgroundImage release];
    
    if (background != nil) {
        self->mBackgroundImage = [background retain];
    } else {
        self->mBackgroundImage = nil;
    }
    
    [self updateSetImage];
}

-(void)setBackgroundImage:(NSImage*)newImage
{
    if (self->mBackgroundImage != nil) [self->mBackgroundImage release];
    
    if (newImage != nil) {
        self->mBackgroundImage = [newImage retain];
    } else {
        self->mBackgroundImage = nil;
    }
    
    [self updateSetImage];
}

-(void)setForegroundImage:(NSImage*)newImage
{
    if (self->mForegroundImage != nil) [self->mForegroundImage release];
    
    if (newImage != nil) {
        self->mForegroundImage = [newImage retain];
    } else {
        self->mForegroundImage = nil;
    }
    
    [self updateSetImage];
}

-(void)updateSetImage
{
    if (self->mBackgroundImage == nil) {
        if (self->mForegroundImage != nil) {
            [self setImage:self->mForegroundImage];
        }
        
    } else {
        if (self->mForegroundImage == nil) {
            [self setImage:self->mBackgroundImage];
        
        } else {
            // Both images set, draw composite
            NSImage* drawArea = [self->mBackgroundImage copy];
            
            // Determine actual (bitmap) sizes for drawing purposes
            // http://borkware.com/quickies/one?topic=NSImage
            NSArray* imageReps;
            NSImageRep* imageRep;
            
            NSSize bgSize;
            imageReps = [self->mBackgroundImage representations];
            imageRep  = [imageReps objectAtIndex:0];
            bgSize.width  = [imageRep pixelsWide];
            bgSize.height = [imageRep pixelsHigh];
            
            NSSize fgSize;
            imageReps = [self->mForegroundImage representations];
            imageRep  = [imageReps objectAtIndex:0];
            fgSize.width  = [imageRep pixelsWide];
            fgSize.height = [imageRep pixelsHigh];
            
            // Set actual (bitmap) representation sizes
            [drawArea setSize:bgSize];
            [self->mForegroundImage setSize:fgSize];
            
            // Use NSImage composite
            // http://www.bdunagan.com/2010/01/25/cocoa-tip-nsimage-composites/
            [drawArea lockFocus];
            
            [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationNone];
            [self->mForegroundImage drawInRect:NSMakeRect(0, 0, bgSize.width, bgSize.height) 
                                      fromRect:NSZeroRect 
                                     operation:NSCompositeSourceOver
                                      fraction:1.0];
            
            [drawArea unlockFocus];
            
            // Restore size
            [drawArea setSize:[self->mBackgroundImage size]];
            
            [self setImage:drawArea];
            [drawArea release];
        }
    }
}

@end

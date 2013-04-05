//
//  BABrainImageView.m
//  ImageDataView
//
//  Created by Oliver Zscheyge on 7/6/12.
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

-(void)mouseUp:(NSEvent*)theEvent {
    
    NSImage* img = [self image];
    
    if (img != nil) {
        NSArray* imgReps = [img representations];
        NSImageRep* imgRep = nil;
        NSSize bitmapSize = {0.0, 0.0};
        
        if ([imgReps count] > 0) {
            NSSize viewSize = [self bounds].size;
            NSLog(@"viewSize: (%lf, %lf)", viewSize.width, viewSize.height);
            
            imgRep = [imgReps objectAtIndex:0];
            bitmapSize = [imgRep size];
            NSLog(@"ImageRepSize: (%lf, %lf)", bitmapSize.width, bitmapSize.height);
            
//            NSSize actualRepSize;
//            actualRepSize.width  = [imgRep pixelsWide];
//            actualRepSize.height = [imgRep pixelsHigh];
//            NSLog(@"Actual size: (%lf, %lf))", actualRepSize.width, actualRepSize.height);
            
            NSSize scaleFactors;
            scaleFactors.width = bitmapSize.width / viewSize.width;
            scaleFactors.height = bitmapSize.height / viewSize.height;
            NSLog(@"Scale factors: (%lf, %lf)", scaleFactors.width, scaleFactors.height);
            
            NSPoint clickPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
            NSPoint clickPointImageSpace;
            
            if (scaleFactors.width > scaleFactors.height) {
                clickPointImageSpace.x = scaleFactors.width * clickPoint.x;
                clickPointImageSpace.y = (viewSize.height * scaleFactors.width)
                                         - (clickPoint.y * scaleFactors.width) - ((viewSize.height * scaleFactors.width - bitmapSize.height) / 2)
                                         - 1.0f;
            } else {
                clickPointImageSpace.x = (clickPoint.x * scaleFactors.height) - ((viewSize.width * scaleFactors.height - bitmapSize.width) / 2);
                clickPointImageSpace.y = bitmapSize.height - (scaleFactors.height * clickPoint.y) - 1.0f;
            }
            
            clickPointImageSpace.x = floor(clickPointImageSpace.x);
            clickPointImageSpace.y = round(clickPointImageSpace.y);
            
            NSLog(@"ClickPoint in ImageSpace: (%.1lf, %.1lf)", clickPointImageSpace.x, clickPointImageSpace.y);

            
            // Draw clicked point directly into the view's image in red color.
            // For debug/development purposes only!
            NSSize imgSize = [img size];
            NSLog(@"ImageSize: (%lf, %lf)", imgSize.width, imgSize.height);
            
            [img setSize:bitmapSize];
            [img lockFocus];
            NSBitmapImageRep* bitmapRep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:NSMakeRect(0.0, 0.0, [img size].width, [img size].height)];
            [img unlockFocus];
            
            NSUInteger* pixelData = (NSUInteger*) malloc(sizeof(NSUInteger) * 4);
            pixelData[0] = 255;
            pixelData[1] = 0;
            pixelData[2] = 0;
            pixelData[3] = 255;
            [bitmapRep setPixel:pixelData atX:clickPointImageSpace.x y:clickPointImageSpace.y];
            free(pixelData);
            
            NSImage* newImg = [[NSImage alloc] initWithSize:bitmapSize];
            [newImg addRepresentation:bitmapRep];
            [newImg setScalesWhenResized:YES];
            [newImg setSize:imgSize];
            NSLog(@"NewImageSize: (%lf, %lf)", newImg.size.width, newImg.size.height);
            
            [self setImage:newImg];
            [newImg release];
            [bitmapRep release];
    
            if (   clickPointImageSpace.x >= 0 && clickPointImageSpace.x < bitmapSize.width
                && clickPointImageSpace.y >= 0 && clickPointImageSpace.y < bitmapSize.height) {
                // Propagate mouse event with corrected click coordinates (in image space)
                // if it actually is inside the image.
                NSEvent* correctedEvent = [NSEvent mouseEventWithType:[theEvent type]
                                                             location:clickPointImageSpace
                                                        modifierFlags:[theEvent modifierFlags]
                                                            timestamp:[theEvent timestamp]
                                                         windowNumber:[theEvent windowNumber]
                                                              context:[theEvent context]
                                                          eventNumber:[theEvent eventNumber]
                                                           clickCount:[theEvent clickCount]
                                                             pressure:[theEvent pressure]];
                
                [super mouseUp:correctedEvent];
            }
        }
    }
    
//    NSRect viewFrame = self.frame; // Position und Größe im Fenster
//    NSSize cellSize = [self.cell cellSize]; // bringt nichts
    
//    [self setNeedsDisplay:YES];
}

@end

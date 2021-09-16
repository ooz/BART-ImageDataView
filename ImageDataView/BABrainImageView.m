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

/** Return the NSImage that is "closest" to the viewer. Ignoring the selection image!
 *
 * \return The topmost NSImage. Ignoring the selection image.
 *         If a foreground is active, it is returned.
 *         If no foreground is active, but a background is set, the background is returned.
 *         Nil if neither fore- or background are set.
 */
-(NSImage*)getTopmostImage;

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

-(void)setImages:(NSImage*)selection
              on:(NSImage*)foreground
              on:(NSImage*)background
{
    if (self->mSelectionImage != nil) [self->mSelectionImage release];
    
    if (selection != nil) {
        self->mSelectionImage = [selection retain];
    } else {
        self->mSelectionImage = nil;
    }
    
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

-(void)setSelectionImage:(NSImage*)newImage
{
    if (self->mSelectionImage != nil) [self->mSelectionImage release];
    
    if (newImage != nil) {
        self->mSelectionImage = [newImage retain];
    } else {
        self->mSelectionImage = nil;
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


-(NSImage*)createCompositeImage:(NSImage*)foreground
                             on:(NSImage*)background
{
    if (background == nil) {
        if (foreground != nil) {
            return [foreground copy];
        } else {
            return nil;
        }
    } else {
        if (foreground == nil) {
            return [background copy];
        } else {
            // Both arguments are not nil, actually draw composite
            NSImage* drawArea = [background copy];
            
            // Determine actual (bitmap) sizes for drawing purposes
            // http://borkware.com/quickies/one?topic=NSImage
            NSArray* imageReps;
            NSImageRep* imageRep;
            
            NSSize bgSize;
            imageReps = [background representations];
            imageRep  = [imageReps objectAtIndex:0];
            bgSize.width  = [imageRep pixelsWide];
            bgSize.height = [imageRep pixelsHigh];
            
            NSSize fgSize;
            imageReps = [foreground representations];
            imageRep  = [imageReps objectAtIndex:0];
            fgSize.width  = [imageRep pixelsWide];
            fgSize.height = [imageRep pixelsHigh];
            
            // Set actual (bitmap) representation sizes
            [drawArea setSize:bgSize];
            [foreground setSize:fgSize];
            
            // Use NSImage composite
            // http://www.bdunagan.com/2010/01/25/cocoa-tip-nsimage-composites/
            [drawArea lockFocus];
            
            [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationNone];
            [foreground drawInRect:NSMakeRect(0, 0, bgSize.width, bgSize.height)
                          fromRect:NSZeroRect
                         operation:NSCompositeSourceOver
                          fraction:1.0];
            
            [drawArea unlockFocus];
            
            // Restore size
            [drawArea setSize:[background size]];
            
            return drawArea;
        }
    }
}

-(void)updateSetImage
{
    // All three images present.
    if (self->mSelectionImage != nil && self->mForegroundImage != nil && self->mBackgroundImage != nil) {
        NSImage* composite  = [self createCompositeImage:self->mSelectionImage
                                                      on:self->mForegroundImage];
        NSImage* composite2 = [self createCompositeImage:composite
                                                      on:self->mBackgroundImage];
        [self setImage:composite2];
        [composite2 release];
        [composite  release];
        return;
    }
    
    // Single image.
    if (self->mSelectionImage != nil && self->mForegroundImage == nil && self->mBackgroundImage == nil) {
        return [self setImage:self->mSelectionImage];
    }
    if (self->mSelectionImage == nil && self->mForegroundImage != nil && self->mBackgroundImage == nil) {
        return [self setImage:self->mForegroundImage];
    }
    if (self->mSelectionImage == nil && self->mForegroundImage == nil && self->mBackgroundImage != nil) {
        return [self setImage:self->mBackgroundImage];
    }
    
    // Two images.
    NSImage* fg = nil;
    NSImage* bg = nil;
    if (self->mSelectionImage != nil && self->mForegroundImage != nil && self->mBackgroundImage == nil) {
        fg = self->mSelectionImage;
        bg = self->mForegroundImage;
    }
    if (self->mSelectionImage == nil && self->mForegroundImage != nil && self->mBackgroundImage != nil) {
        fg = self->mForegroundImage;
        bg = self->mBackgroundImage;
    }
    if (self->mSelectionImage != nil && self->mForegroundImage == nil && self->mBackgroundImage != nil) {
        fg = self->mSelectionImage;
        bg = self->mBackgroundImage;
    }
    
    if (fg != nil && bg != nil) {
        NSImage* composite = [self createCompositeImage:fg
                                                     on:bg];
        [self setImage:(NSImage*) composite];
        [composite release];
    }
}

-(NSImage*)getTopmostImage
{
    if (self->mForegroundImage != nil) {
        return self->mForegroundImage;
    }
    
    return self->mBackgroundImage;
}

-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary *)change
                      context:(void *)context
{
    if ([keyPath isEqualToString:@"renderedImage"]) {
        if ([(NSString*) context isEqualToString:@"selection"]) {
            id newVal = [change objectForKey:NSKeyValueChangeNewKey];
            if (newVal == [NSNull null]) {
                newVal = nil;
            }
            [self setSelectionImage:newVal];
        }
    }
}

-(void)mouseUp:(NSEvent*)theEvent {
    
    NSImage* img = [self getTopmostImage];
    
    if (img != nil) {
        NSArray* nsimgReps = [img representations];
        NSImageRep* nsimgRep = nil;
        NSSize bitmapSize = {0.0, 0.0};
        
        if ([nsimgReps count] > 0) {
            NSSize viewSize = [self bounds].size;
            NSLog(@"###########################################################");
            NSLog(@"ViewSize:      (%lf, %lf)", viewSize.width, viewSize.height);
            NSSize nsimgSize = [img size];
            NSLog(@"ImgSize:       (%lf, %lf)", nsimgSize.width , nsimgSize.height);
            
            nsimgRep = [nsimgReps objectAtIndex:0];
            bitmapSize = [nsimgRep size];
            NSLog(@"ImageRepSize:  (%lf, %lf)", bitmapSize.width, bitmapSize.height);
            
            NSSize nsimgScale;
            nsimgScale.width  = nsimgSize.width  / viewSize.width;
            nsimgScale.height = nsimgSize.height / viewSize.height;
            NSLog(@"ImgScaleFactors: (%lf, %lf)", nsimgScale.width, nsimgScale.height);

            NSPoint clickViewSpace = [self convertPoint:[theEvent locationInWindow] fromView:nil];
            NSPoint clickImgSpace;
            
            // Convert click from view space to NSImage space
            if (nsimgScale.width > nsimgScale.height) {
                // NSImage completely fills the view in the x axis
                clickImgSpace.x = clickViewSpace.x * nsimgScale.width;
                clickImgSpace.y = (viewSize.height * nsimgScale.width)
                                    - (clickViewSpace.y * nsimgScale.width)
                                    - ((viewSize.height * nsimgScale.width - nsimgSize.height) / 2.0f);
            } else {
                // NSImage completely fills the view in the y axis
                clickImgSpace.x = (clickViewSpace.x * nsimgScale.height)
                                    - ((viewSize.width * nsimgScale.height - nsimgSize.width) / 2.0f);
                clickImgSpace.y = nsimgSize.height - (clickViewSpace.y * nsimgScale.height);
            }
            
            // Scale from NSImage size to NSImageRep size
            clickImgSpace.x = (clickImgSpace.x / nsimgSize.width ) * bitmapSize.width;
            clickImgSpace.y = (clickImgSpace.y / nsimgSize.height) * bitmapSize.height;
            clickImgSpace.x = floor(clickImgSpace.x);
            clickImgSpace.y = floor(clickImgSpace.y);
            NSLog(@"ClickPoint original:    (%.1lf, %.1lf)", clickViewSpace.x          , clickViewSpace.y          );
            NSLog(@"ClickPoint in ImgSpace: (%.1lf, %.1lf)", clickImgSpace.x, clickImgSpace.y);
    
            
            if (   clickImgSpace.x >= 0 && clickImgSpace.x < bitmapSize.width
                && clickImgSpace.y >= 0 && clickImgSpace.y < bitmapSize.height) {
                // Propagate mouse event with corrected click coordinates (in image space)
                // if it actually is inside the image.
                NSEvent* correctedEvent = [NSEvent mouseEventWithType:[theEvent type]
                                                             location:clickImgSpace
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

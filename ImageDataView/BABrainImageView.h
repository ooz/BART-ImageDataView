//
//  BABrainImageView.h
//  ImageDataView
//
//  Created by Oliver Z. on 7/6/12.
//  Copyright (c) 2012 MPI CBS. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "EDDataElement.h"

/** Custom NSImageView for displaying brain images (with overlay support).
 * If just one image should be shown (no overlay) it does not matter if
 * it is set as foreground or as background image.
 *
 * Image interpolation is disabled!
 */
@interface BABrainImageView : NSImageView {
    
    NSImage* mBackgroundImage;
    NSImage* mForegroundImage;
    
}

/** Convenience method to set both back- and foreground in one function call.
 *
 * \param foreground Foreground NSImage. Pass nil if no foreground should be present.
 * \param background Background NSImage. Pass nil if no background should be present.
 */
-(void)setImages:(NSImage*)foreground 
              on:(NSImage*)background;

/** Sets the foreground NSImage.
 *
 * \param newImage NSImage to set as foreground. Pass nil if no foreground is wanted. */
-(void)setForegroundImage:(NSImage*)newImage;

/** Sets the background NSImage.
 *
 * \param newImage NSImage to set as background. Pass nil if no background is wanted. */
-(void)setBackgroundImage:(NSImage*)newImage;

@end

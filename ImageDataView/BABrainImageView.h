//
//  BABrainImageView.h
//  ImageDataView
//
//  Created by Oliver Z. on 7/6/12.
//  Copyright (c) 2012 MPI CBS. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "EDDataElement.h"

/** Custom NSImageView for displaying brain images (with overlay and voxel selection support).
 * If just one image should be shown (no overlay) it does not matter if it is set as 
 * foreground or as background image.
 *
 * Another image can be set to mark a selection of voxels (shown on top of foreground and
 * background images).
 * The view offers support for observing the keypath "renderedImage" in the context "selection"
 * meaning it updates its selection image if an observed object's renderedImage property is
 * changed.
 *
 * Image interpolation is disabled!
 */
@interface BABrainImageView : NSImageView {
    
    /** Image marking selected voxels (e.g. ROI). */
    NSImage* mSelectionImage;
    /** Foreground image. Usually an overlay of functional/activation or derived data. */
    NSImage* mForegroundImage;
    /** Background image. Usually anatomical data or an anatomical reference image. */
    NSImage* mBackgroundImage;
    
}

/** Sets selection, foreground and background image in one function call.
 *
 * \param selection  NSImage marking selected voxels. Pass nil for no voxel selection(s).
 * \param foreground Foreground NSImage. Pass nil if no foreground should be present.
 * \param background Background NSImage. Pass nil if no background should be present.
 */
-(void)setImages:(NSImage*)selection
              on:(NSImage*)foreground
              on:(NSImage*)background;

/** Sets the selection NSImage.
 * The selection image marks selected voxels (e.g. ROI) in the view.
 *
 * \param newImage NSImage representing selected voxels. Pass nil for no voxel selection(s).
 */
-(void)setSelectionImage:(NSImage*)newImage;

/** Sets the foreground NSImage.
 *
 * \param newImage NSImage to set as foreground. Pass nil if no foreground is wanted. */
-(void)setForegroundImage:(NSImage*)newImage;

/** Sets the background NSImage.
 *
 * \param newImage NSImage to set as background. Pass nil if no background is wanted. */
-(void)setBackgroundImage:(NSImage*)newImage;


/** Creates a new image being the composite of a foreground drawn on a background image.
 * If one argument is nil and the other isn't, it returns a copy of the non nil argument.
 * If both arguments are nil, this method returns nil.
 *
 * \param foreground Foreground NSImage. Pass nil if no foreground is wanted.
 * \param background Background NSImage. Pass nil if no background is wanted.
 * \return A new NSImage being the composite of foreground on background.
 *         MEMORY MANAGEMENT: Caller is responsible for releasing the created NSImage object!
 *         Nil if both foreground and background are nil.
 */
-(NSImage*)createCompositeImage:(NSImage*)foreground
                             on:(NSImage*)background;

@end

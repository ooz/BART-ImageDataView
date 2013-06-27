Integration notice
==================

 * MainMenu.xib contains just a dummy window to test the view.
   The actual view is contained in BAImageDataView.xib
 * AppDelegate.m can be seen as an example for view integration in the main app.
 * Timestep information is not intended to be manipulated by the user.
   The view controller BAImageDataViewController allows to set the appropriate 
   timestep.


TODO
====

 * Filter slices without relevant information. Such slice filters should be subclasses
   of BAImageSliceSelector (low priority)
 * Overlay: What happens if background/overlay are not in the same space?
   (What happens to the slice/orientation selection tools?)
   
Issues
======

 * It can happen that the CIFilter is not applied correctly.
   (e.g. blue-red colortable: one color is missing)

ROI
---

 * View has certain dead spot(s) not pushing mouse click events down the
   responder chain (although mouse events correctly registered by the view
   class).
   Possible future fix:
    1. Make (corrected) click point a property of the view class
    2. Let the controller KV observe it
    3. Remove BAImageDataViewController from the responder chain
     
 * Directly after activating an overlay the ROI selected on the current slice
   isn't displayed (although selection is registered and handled properly on
   the lower levels).
   Workaround: 
    1. Switch slice
    2. Switch back to the slice you wanted to select the ROI on
    3. Select ROI as normal

 * If background image and overlay aren't in the same space (should not be!),
   ROI selection might be 1 or more voxel off the point that was actually
   clicked. 


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

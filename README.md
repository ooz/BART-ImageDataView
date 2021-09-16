ObjC/Cocoa view component to display brain image data.
Developed to be integrated into the BART application. 


Features
========

 * Displays 4D MRT data in axial, sagittal, coronal orientation
 * Single slice or multiple slice (grid) view possible
 * Overlay support e.g. for functional data
 * Colortables can be applied to overlays
 * ROIs can be selected 


Integration notice
==================

 * MainMenu.xib contains just a dummy window to test the view.
   The actual view is contained in BAImageDataView.xib
 * AppDelegate.m can be seen as an example for view integration in the main app.
 * Timestep information is not intended to be manipulated by the user.
   The view controller BAImageDataViewController allows to set the appropriate 
   timestep.


Important classes
=================

 * BAImageDataViewController
   Primary controller:
   - setting of EDDataElements (MRI data)
   - add/set overlays
   - get ROI controller

 * BADataElementRenderer
   Takes care of the EDDataElement --> NSImage conversion.
   Encapsulates all the orientation, voxel size/gap, row/col vec and other
   things that have an impact on the final image.
   Also translates points in the rendered NSImage back to voxels in the
   original data.
 * BAImageSliceSelector
   Selects the slices to be displayed in the grid view if the grid shows
   less slices than the original data offers.
 * BAImageFilter
   High level CIFilter with colortable and parameters (e.g. min, max).
   Used to display colortables as well as the ROI selection.

 * BABrainImageView
   View class displaying the rendered NSImages.
   Allows composition of multiple layers and is the first to receive
   mouse events (e.g. for ROI selection)

 * ROI/BAROIController
   Subcontroller for ROIs.
   ROI selections are stored in BAROISelection objects. Those can be
   stacked in a hierarchical compositon. The selections can be rendered
   as a binary map (type: EDDataElement). This allows them to be treated
   as normal data (e.g. written to disk, displayed in the view)

   
TODO
====

 * Filter slices without relevant information. Such slice filters should be 
   subclasses of BAImageSliceSelector (low priority)
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

    1. Click on the ROI you want to select, you won't get any visual feedback
    2. Switch slice or orientation or to grid layout
    3. Switch back to the slice/orientation/grid you selected the ROI on.
       You will now see the ROI selected in (1.)
    4. All following selections work as expected

 * If background image and overlay aren't in the same space (should not be!),
   ROI selection might be 1 or more voxel off the point that was actually
   clicked. 


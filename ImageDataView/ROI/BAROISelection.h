//
//  BAROISelection.h
//  ImageDataView
//
//  Created by Oliver Z. on 3/19/13.
//
//

#import <Foundation/Foundation.h>

@class EDDataElement;

/**
 * Enum describing whether to add or to remove a ROI selection from
 * the previous selection.
 */
enum ROISelectionMode {
    ADD = 0,
    REMOVE
};



/** Superclass for all ROISelection classes.
 * Allows construction of a hierarchical ROI selection tree and the
 * conversion to a binary mask (EDDataElement).
 */
@interface BAROISelection : NSObject {
    
    BAROISelection* mParent;
    
    NSMutableArray* mChildren;
    
    enum ROISelectionMode mMode;
    
}

/** Initializer.
 *
 * \param m ROISelectionMode indicating whether the selection should be
 *          added or subtracted.
 */
-(id)initWithMode:(enum ROISelectionMode)m;

// Properties
@property (readonly) BAROISelection* parent;
-(NSArray*)children;
-(enum ROISelectionMode)mode;


// Tree mutators
-(void)addChild:(BAROISelection*)child;
-(void)removeChild:(BAROISelection*)child;


// #####################
// # Converter methods #
// #####################

///**
// * Converts the ROI selection to a binary mask.
// *
// * \return Binary mask represented by an EDDataElement with voxel values of 0.0 and 1.0.
// *         Autoreleased;
// */
//-(EDDataElement*)asBinaryMask;

/**
 * "Draws" the ROI selection on an existing binary mask.
 *
 * \param mask Binary mask (EDDataElement with 0.0 and 1.0 voxel values).
 * \return     The same EDDataElement as the parameter mask with this additional
 *             selection rendered onto it.
 */
-(EDDataElement*)addToBinaryMask:(EDDataElement*)mask;

//-(NSArray*)asPointSet;

@end

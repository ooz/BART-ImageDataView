//
//  BAROISelection.h
//  ImageDataView
//
//  Created by Oliver Zscheyge on 3/19/13.
//
//

#import <Foundation/Foundation.h>

@class EDDataElement;

@interface BAROISelection : NSObject {
    
    BAROISelection* mParent;
    
    NSMutableArray* mChildren;
    
    NSString* mLabel;
    
}

// Properties
-(NSString*)label;
@property (readonly) BAROISelection* parent;
-(NSArray*)children;


// Tree mutators
-(void)addChild:(BAROISelection*)child;
-(void)removeChild:(BAROISelection*)child;


// #####################
// # Converter methods #
// #####################

/**
 * Converts the ROI selection to a binary mask.
 *
 * \return Binary mask represented by an EDDataElement with voxel values of 0.0 and 1.0.
 *         Autoreleased;
 */
-(EDDataElement*)asBinaryMask;

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

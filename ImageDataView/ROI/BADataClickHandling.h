//
//  BADataClickHandling.h
//  ImageDataView
//
//  Created by Oliver Z. on 4/23/13.
//
//

#import <Foundation/Foundation.h>

@class EDDataElement;
@class BADataVoxel;

/**
 * Protocol for communicating with the ROIController.
 */
@protocol BADataClickHandling <NSObject>

/**
 * Handler for "clicking" on a DataElement at a given 4D point.
 *
 * \param data EDDataElement defining the image space (main orientation and dimensions).
 * \param p    BADataVoxel (4D point) that was clicked in the space of the parameter data.
 */
-(void)clickOn:(EDDataElement*)data at:(BADataVoxel*)p;

/**
 * Handler for "clicking" on a DataElement at a given 4D point only taking voxels into account 
 * that are within a range given by the parameters min and max.
 *
 * \param data EDDataElement defining the image space (main orientation and dimensions).
 * \param p    BADataVoxel (4D point) that was clicked in the space of the parameter data.
 * \param min  Float minimum boundary. Should be within absolute (min, max) of the parameter data.
 * \param max  Float maximum boundary. Should be within absolute (min, max) of the parameter data.
 */
-(void)clickOn:(EDDataElement*)data at:(BADataVoxel*)p inRange:(float)min and:(float)max;

@end

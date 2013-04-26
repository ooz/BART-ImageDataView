//
//  BADataClickHandling.h
//  ImageDataView
//
//  Created by Oliver Zscheyge on 4/23/13.
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

@end

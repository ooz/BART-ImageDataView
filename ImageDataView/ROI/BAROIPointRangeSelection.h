//
//  BAROIPointRangeSelection.h
//  ImageDataView
//
//  Created by Oliver Zscheyge on 5/14/13.
//
//

#import "BAROIPointThresholdSelection.h"

@interface BAROIPointRangeSelection : BAROIPointThresholdSelection {

    /** Upper bound of the value range to select in. */
    float mMax;
    
    // Note: the lower bound property (min) is stored in the property
    //       super->mThreshold
    
}

@property (nonatomic, readonly) float max;

/** Initializer.
 */
-(id)initWithReference:(EDDataElement*)data
                 point:(BADataVoxel*)p
                  mode:(enum ROISelectionMode)m
               inRange:(float)min
                   and:(float)max;

@end

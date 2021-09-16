//
//  BAROIPointRangeSelection.h
//  ImageDataView
//
//  Created by Oliver Z. on 5/14/13.
//
//

#import "BAROIPointThresholdSelection.h"

/**
 * ROI selection based on a voxel (determined e.g. by clicking a point)
 * and a given lower and upper boundary.
 * All adjacent voxels whose values are within the boundaries will be
 * selected.
 */
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

//
//  BAROIPointThresholdSelection.h
//  ImageDataView
//
//  Created by Oliver Z. on 3/19/13.
//
//

#import <Foundation/Foundation.h>

#import "BAROISelection.h"

@class BADataVoxel;

/**
 * ROI selection based on a voxel (determined e.g. by clicking a point)
 * and a given threshold.
 * All adjacent voxels whose values are above the threshold will be
 * selected.
 */
@interface BAROIPointThresholdSelection : BAROISelection {

    EDDataElement* mReference;
    
    BADataVoxel* mPoint;    
    float mThreshold;
    
}

@property (nonatomic, readonly) BADataVoxel* point;
@property (nonatomic, readonly) float threshold;

-(id)initWithReference:(EDDataElement*)data
                 point:(BADataVoxel*)p
                  mode:(enum ROISelectionMode)m
          andThreshold:(float)thres;

@end

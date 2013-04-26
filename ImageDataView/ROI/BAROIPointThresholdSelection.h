//
//  BAROIPointThresholdSelection.h
//  ImageDataView
//
//  Created by Oliver Zscheyge on 3/19/13.
//
//

#import <Foundation/Foundation.h>

#import "BAROISelection.h"

@class BADataVoxel;

@interface BAROIPointThresholdSelection : BAROISelection {

    EDDataElement* mReference;
    
    BADataVoxel* mPoint;
    
    NSNumber* mThreshold;
    
}

@property (nonatomic, readonly) BADataVoxel* point;
@property (nonatomic, readonly) NSNumber* threshold;

-(id)initWithReference:(EDDataElement*)data
                 point:(BADataVoxel*)p
          andThreshold:(NSNumber*)thres;

@end

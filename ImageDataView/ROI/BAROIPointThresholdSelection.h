//
//  BAROIPointThresholdSelection.h
//  ImageDataView
//
//  Created by Oliver Zscheyge on 3/19/13.
//
//

#import <Foundation/Foundation.h>

#import "BAROISelection.h"

@interface BAROIPointThresholdSelection : BAROISelection {

    // FIXME: introduce proper point type
    NSObject* mPoint;
    
    NSNumber* mThreshold;
    
}

@property (nonatomic, readonly) NSObject* point;
@property (nonatomic, readonly) NSNumber* threshold;

-(id)initWithPoint:(NSObject*)p andThreshold:(NSNumber*)thres;

@end

//
//  BAROIPointSetSelection.h
//  ImageDataView
//
//  Created by Oliver Z. on 3/19/13.
//
//

#import <Foundation/Foundation.h>

#import "BAROISelection.h"

@interface BAROIPointSetSelection : BAROISelection {
    
    NSArray* mPoints;
    
}

@property (nonatomic, readonly) NSArray* points;

-(id)initWithPoints:(NSArray*)points;

@end

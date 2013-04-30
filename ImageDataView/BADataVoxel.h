//
//  BADataVoxel.h
//  ImageDataView
//
//  Created by Oliver Zscheyge on 4/23/13.
//
//

#import <Foundation/Foundation.h>
#import "EDDataElement.h"

/** 
 * Class representing a 4D point.
 */
@interface BADataVoxel : NSObject {
    
}

@property (readonly) NSUInteger column;
@property (readonly) NSUInteger row;
@property (readonly) NSUInteger slice;
@property (readonly) NSUInteger timestep;

/** Initializer.
 */
-(id)initWithColumn:(NSUInteger)c
                row:(NSUInteger)r
              slice:(NSUInteger)s
           timestep:(NSUInteger)ts;

/**
 * Converts this voxel object (in place) from one orientation to another.
 *
 * \param srcOrient The ImageOrientation this voxel is assumed to be in (currently).
 * \param tarOrient The ImageOrientation this voxel should be converted to.
 */
-(void)convertFrom:(enum ImageOrientation)srcOrient
                to:(enum ImageOrientation)tarOrient;

@end

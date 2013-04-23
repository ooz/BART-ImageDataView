//
//  BADataVoxel.h
//  ImageDataView
//
//  Created by Oliver Zscheyge on 4/23/13.
//
//

#import <Foundation/Foundation.h>

@interface BADataVoxel : NSObject {
    
}

@property (readonly) NSUInteger column;
@property (readonly) NSUInteger row;
@property (readonly) NSUInteger slice;
@property (readonly) NSUInteger timestep;

-(id)initWithColumn:(NSUInteger)c
                row:(NSUInteger)r
              slice:(NSUInteger)s
           timestep:(NSUInteger)ts;

@end

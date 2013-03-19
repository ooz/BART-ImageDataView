//
//  BAROISelection.h
//  ImageDataView
//
//  Created by Oliver Zscheyge on 3/19/13.
//
//

#import <Foundation/Foundation.h>

@class EDDataElement;

@interface BAROISelection : NSObject {
    
    BAROISelection* mParent;
    
    NSMutableArray* mChildren;
    
    NSString* mLabel;
    
}

// Properties
-(NSString*)label;
@property (readonly) BAROISelection* parent;
-(NSArray*)children;


// Tree mutators
-(void)addChild:(BAROISelection*)child;
-(void)removeChild:(BAROISelection*)child;


// Converter methods
-(EDDataElement*)asBinaryMask;
-(NSArray*)asPointSet;

@end

//
//  BAImageData.h
//  ImageDataView
//
//  Created by Oliver Zscheyge on 6/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

@interface BAImageDataViewController : NSViewController {
    
    // Bottom controls
    

}

@property (readonly) IBOutlet NSScrollView* mScrollView;
@property (readonly) IBOutlet IKImageView* mBrainImage;

@property (readonly) IBOutlet NSSegmentedControl* mOrientationSelect;
@property (readonly) IBOutlet id mGridSizeSelect;
@property (readonly) IBOutlet id mSliceSelect;
@property (readonly) IBOutlet id mSliceSelectSlider;

-(IBAction)setOrientation:(id)sender;
-(IBAction)setGridSize:(id)sender;
-(IBAction)selectSlice:(id)sender;

@end

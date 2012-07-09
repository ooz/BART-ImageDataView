//
//  BAImageData.h
//  ImageDataView
//
//  Created by Oliver Zscheyge on 6/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>


@class EDDataElement;


typedef enum ImageOrientationEnum {
    SAGITTAL,
    AXIAL,
    CORONAR
} ImageOrientation;


@interface BAImageDataViewController : NSViewController {
    
    EDDataElement* mImage;
    uint mCurrentSlice;
    uint mSliceCount;
    uint mCurrentTimestep;
   
    ImageOrientation mOrientation;
    NSSize mGridSize;

}


@property (readonly) IBOutlet NSImageView* mImageView;

@property (readonly) IBOutlet NSSegmentedControl* mOrientationSelect;
@property (readonly) IBOutlet id mGridSizeSelect;
@property (readonly) IBOutlet NSTextField* mSliceSelect;
@property (readonly) IBOutlet NSSlider*    mSliceSelectSlider;

-(IBAction)setOrientation:(id)sender;
-(IBAction)setGridSize:(id)sender;
-(IBAction)selectSlice:(id)sender;


-(void)showImage:(EDDataElement*)image;
-(void)showImage:(EDDataElement*)image
         slice:(uint)sliceNr
    atTimestep:(uint)tstep;


@end

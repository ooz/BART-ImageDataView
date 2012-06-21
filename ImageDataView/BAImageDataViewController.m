//
//  BAImageData.m
//  ImageDataView
//
//  Created by Oliver Zscheyge on 6/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BAImageDataViewController.h"

@interface BAImageDataViewController ()

@end

@implementation BAImageDataViewController

@synthesize mScrollView;
@synthesize mBrainImage;

@synthesize mOrientationSelect;
@synthesize mGridSizeSelect;
@synthesize mSliceSelect;
@synthesize mSliceSelectSlider;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
        
//        NSView* content = [[NSView alloc] init];
//        [content add]
//        self.mBrainImage.hasVerticalScroller = YES;
//        [self.mScrollView setContentView:self.mBrainImage];
    }
    
    return self;
}

-(IBAction)setOrientation:(id)sender
{
    if (sender == self.mOrientationSelect) {
        NSLog(@"Selected segment (orientation selector): %li", [self.mOrientationSelect selectedSegment]);
        [self.mBrainImage setImageWithURL:[NSURL URLWithString:@"http://www.cbs.mpg.de/institute/building/mpi3n"]];
    }
}

-(IBAction)setGridSize:(id)sender
{
    if (sender == self.mGridSizeSelect) {
        NSLog(@"GridSize changed");
    }
}

-(IBAction)selectSlice:(id)sender
{
    if (sender == self.mSliceSelect) {
        NSLog(@"Slice changed (text field)");
        
    } else if (sender == self.mSliceSelectSlider) {
        NSLog(@"Slice changed (slider)");
    }
}

@end

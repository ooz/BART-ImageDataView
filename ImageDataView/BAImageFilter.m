//
//  BAImageFilter.m
//  ImageDataView
//
//  Created by Oliver Zscheyge on 9/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BAImageFilter.h"

@implementation BAImageFilter

-(id)init
{
    if (self = [super init]) {
        self->mFilter = nil;
    }
    
    return self;
}

-(void)dealloc
{
    if (self->mFilter != nil) 
        [self->mFilter release];
    
    [super dealloc];
}

-(CIFilter*)filter
{
    return self->mFilter;
}

-(CIImage*)apply:(CIImage*)on
{
    return nil;
}

@end

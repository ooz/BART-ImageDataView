//
//  BASingleDomainColortableFilter.m
//  ImageDataView
//
//  Created by Oliver Zscheyge on 9/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BASingleDomainColortableFilter.h"

@implementation BASingleDomainColortableFilter

-(id)init
{
    if (self = [super init]) {
        self->mColortable = nil;
    }
    
    return self;
}

-(void)dealloc
{
    if (self->mColortable != nil) 
        [self->mColortable release];
    
    [super dealloc];
}

@end

//
//  BAImageFilter.m
//  ImageDataView
//
//  Created by Oliver Zscheyge on 9/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BAImageFilter.h"

static const NSUInteger INITIAL_PARAMS_SIZE = 2;

@implementation BAImageFilter

-(id)init
{
    if (self = [super init]) {
        self->mFilter = nil;
        self->mParams = [[NSMutableDictionary alloc] initWithCapacity:INITIAL_PARAMS_SIZE];
    }
    
    return self;
}

-(void)dealloc
{
    if (self->mFilter != nil) 
        [self->mFilter release];
    [self->mParams release];
    
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

-(void)setValue:(id)value forKey:(NSString *)key
{
    [self->mParams setValue:value forKey:key];
}

-(id)valueForKey:(NSString *)key
{
    return [self->mParams valueForKey:key];
}

@end

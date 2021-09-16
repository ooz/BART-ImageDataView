//
//  BAImageFilter.m
//  ImageDataView
//
//  Created by Oliver Z. on 9/14/12.
//  Copyright (c) 2012 MPI CBS. All rights reserved.
//

#import "BAImageFilter.h"

/** Initial size of the dynamical resized parameter dictionary. */
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

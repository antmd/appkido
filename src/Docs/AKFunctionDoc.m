/*
 * AKFunctionDoc.m
 *
 * Created by Andy Lee on Tue Mar 16 2004.
 * Copyright (c) 2003, 2004 Andy Lee. All rights reserved.
 */

#import "AKFunctionDoc.h"

@implementation AKFunctionDoc


#pragma mark -
#pragma mark AKDoc methods

- (NSString *)stringToDisplayInDocList
{
    return [[self docName] stringByAppendingString:@" ( )"];
}

@end

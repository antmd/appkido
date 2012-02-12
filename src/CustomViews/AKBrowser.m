/*
 * AKBrowser.m
 *
 * Created by Andy Lee on Mon Jun 02 2003.
 * Copyright (c) 2003, 2004 Andy Lee. All rights reserved.
 */

#import "AKBrowser.h"

@implementation AKBrowser


#pragma mark -
#pragma mark NSView methods

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
    return YES;
}

-(NSColor*)backgroundColor
{
    return [ NSColor colorWithCalibratedWhite:0.9 alpha:1.0 ];
}

-(BOOL)separatesColumns
{
    return YES;
}

@end

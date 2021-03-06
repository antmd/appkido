/*
 * AKWindowSubcontroller.h
 *
 * Created by Andy Lee on Tue Jul 30 2002.
 * Copyright (c) 2003, 2004 Andy Lee. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

#import "AKSubcontroller.h"

@class AKWindowController;
@class AKDatabase;

/*!
 * @class       AKWindowSubcontroller
 * @abstract    Base class for controller objects subordinate to
 *              AKWindowController.
 * @discussion  This base class holds a reference to the owning
 *              AKWindowController.
 */
@interface AKWindowSubcontroller : AKSubcontroller
{
    IBOutlet AKWindowController *_windowController;
}

/*!
 * @brief  Sent by window controller when window containing all of the views is about to close.
 */
-(void)teardown;

@end

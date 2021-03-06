/*
 * AKOldDatabase.h
 *
 * Created by Andy Lee on Thu Jun 27 2002.
 * Copyright (c) 2003, 2004 Andy Lee. All rights reserved.
 */

#import "AKDatabase.h"

@interface AKOldDatabase : AKDatabase
{
@private
    NSString *_devToolsPath;
}


#pragma mark -
#pragma mark Init/awake/dealloc

/*! Designated initializer. */
- (id)initWithDevToolsPath:(NSString *)devToolsPath;

@end

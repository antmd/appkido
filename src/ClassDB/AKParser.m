/*
 * AKParser.m
 *
 * Created by Andy Lee on Sat Mar 06 2004.
 * Copyright (c) 2003, 2004 Andy Lee. All rights reserved.
 */

#import "AKParser.h"

#import "DIGSLog.h"
#import "AKDatabase.h"

@implementation AKParser


#pragma mark -
#pragma mark Class methods

+ (void)recursivelyParseDirectory:(NSString *)dirPath forFramework:(AKFramework *)aFramework
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:dirPath])
    {
        return;
    }

    AKParser *parser = [[self alloc] initWithFramework:aFramework];  // no autorelease

    [parser processDirectory:dirPath recursively:YES];
    [parser release];  // release here
}

+ (void)parseFilesInPaths:(NSArray *)docPaths
    underBaseDir:(NSString *)baseDir
    forFramework:(AKFramework *)aFramework
{
    NSInteger numDocs = [docPaths count];
    NSInteger i;
    for (i = 0; i < numDocs; i++)
    {
        NSString *docPath = [baseDir stringByAppendingPathComponent:[docPaths objectAtIndex:i]];
        AKParser *parser = [[self alloc] initWithFramework:aFramework];  // no autorelease

        [parser processFile:docPath];
        [parser release];  // release here
    }
}


#pragma mark -
#pragma mark Init/awake/dealloc

- (id)initWithFramework:(AKFramework *)aFramework
{
    if ((self = [super init]))
    {
        _parserFW = [aFramework retain];
    }

    return self;
}

- (id)init
{
    DIGSLogError_NondesignatedInitializer();
    [self release];
    return nil;
}

- (void)dealloc
{
    [_parserFW release];

    [super dealloc];
}


#pragma mark -
#pragma mark Parsing

- (NSMutableData *)loadDataToBeParsed
{
    return [NSMutableData dataWithContentsOfFile:[self currentPath]];
}

- (void)parseCurrentFile
{
    DIGSLogError_MissingOverride();
}


#pragma mark -
#pragma mark DIGSFileProcessor methods

// Sets things up for -parseCurrentFile to do the real work.
- (void)processCurrentFile
{
    // Set up.
    NSMutableData *fileContents = [self loadDataToBeParsed];

    if (fileContents)
    {
        _dataStart = [fileContents bytes];
        _current = _dataStart;
        _dataEnd = _dataStart + [fileContents length];
    }
    else
    {
        _dataStart = NULL;
        _current = NULL;
        _dataEnd = NULL;
    }

    // Do the job.
    [self parseCurrentFile];

    // Clean up.
    _dataStart = NULL;
    _current = NULL;
    _dataEnd = NULL;
}

@end

//
//  AKIPhoneDevTools.m
//  AppKiDo
//
//  Created by Andy Lee on 2/11/09.
//  Copyright 2009 Andy Lee. All rights reserved.
//

#import "AKIPhoneDevTools.h"
#import "AKTextUtils.h"


@implementation AKIPhoneDevTools

#pragma mark -
#pragma mark AKDevTools methods

- (NSArray *)docSetSearchPaths
{
    // NOTE: Order matters. On 2011-10-31, Gerriet reported that NSFileVersion (new in 10.7) wasn't
    // appearing in AppKiDo even though it did appear in the Xcode doc window. I reproduced the bug
    // and noticed that I had *two* Lion docsets: one in AKLibraryDocSetDirectory which did not
    // contain NSFileVersion, and a newer one in AKSharedDocSetDirectory which did. So I moved
    // AKSharedDocSetDirectory to the end of this array so that it "wins" when docsets appear in both
    // places. This fixed the problem, at least for me.
    return [NSArray arrayWithObjects:
            [[self devToolsPath] stringByAppendingPathComponent:@"Platforms/iPhoneOS.platform/Developer/Documentation/DocSets/"],
            AKLibraryDocSetDirectory,
            AKSharedDocSetDirectory,
            nil];
}

- (BOOL)isValidDocSetName:(NSString *)fileName
{
    if (![fileName hasPrefix:@"com.apple.adc.documentation.Apple"])
    {
        return NO;
    }
    
    if (![[fileName pathExtension] isEqualToString:@"docset"])
    {
        return NO;
    }
    
    if (![fileName ak_contains:@"iPhone"]  &&  ![fileName ak_contains:@"iOS"])
    {
        return NO;
    }
    
    return YES;
}

- (NSString *)sdkSearchPath
{
    return [[self devToolsPath] stringByAppendingPathComponent:@"Platforms/iPhoneOS.platform/Developer/SDKs/"];
}

@end

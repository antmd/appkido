
//

//  NSObject+DSK.h
//  MailHub
//
//  Created by Ant on 19/01/2010.
//  Copyright 2010 HungerfordRoad Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSObject (DervishSoftwareKit)
- (IMP)  getImplementationOf:(SEL)lookup after:(IMP)skip ;
- (void *)instanceVariableForKey:(NSString *)aKey;

// NSNotificationCenter convenience functions
-(void)registerSelfForNotification:(NSString*)notificationName fromObject:(id)obj callback:(SEL)callback;
-(void)deregisterSelfForNotification:(NSString*)notificationName fromObject:(id)obj;
-(void) propagateValue:(id)value forBinding:(NSString*)binding;


@end

@interface NSObject (AMAssociatedObjects)
- (id)associateValue:(id)value withKey:(void *)key; // Strong reference
- (void)weaklyAssociateValue:(id)value withKey:(void *)key;
- (id)associatedValueForKey:(void *)key;
@end


//
//  NSObject+BlockObservation.h
//  Version 1.0
//
//  Andy Matuschak
//  andy@andymatuschak.org
//  Public domain because I love you. Let me know how you use it.
//

typedef NSString AMBlockToken;
typedef void (^AMBlockTask)(id obj, NSDictionary *change);

@interface NSObject (AMBlockObservation)
- (AMBlockToken *)addObserverForKeyPath:(NSString *)keyPath task:(AMBlockTask)task;
- (AMBlockToken *)addObserverForKeyPath:(NSString *)keyPath onQueue:(NSOperationQueue *)queue task:(AMBlockTask)task;
- (void)invokeChangeTaskForBlockToken:(AMBlockToken *) token;
- (void)removeObserverWithBlockToken:(AMBlockToken *)token;
@end

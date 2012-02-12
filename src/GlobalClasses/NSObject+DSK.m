
//

//  NSObject+DSK.m
//  MailHub
//
//  Created by Ant on 19/01/2010.
//  Copyright 2010 HungerfordRoad Software. All rights reserved.
//

#import "NSObject+DSK.h"
#import <dispatch/dispatch.h>
#import <objc/runtime.h>
#import <objc/runtime.h>

// See http://cocoawithlove.com/2008/03/supersequent-implementation.html

@implementation NSObject (DervishSoftwareKit)


//+ (void) load
//{
//    MH_METHOD_SWIZZLE( NSObject, addObserver:forKeyPath:options:context: ) ;
//    MH_METHOD_SWIZZLE( NSObject, removeObserver:forKeyPath: ) ;
//} /* initialize */


- (void) MH_addObserver:(NSObject *)anObserver forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context
{
    [ self MH_addObserver:anObserver forKeyPath:keyPath options:options context:context ] ;
} /* MH_addObserver */




- (void) MH_removeObserver:(NSObject *)anObserver forKeyPath:(NSString *)keyPath
{
    [ self MH_removeObserver:anObserver forKeyPath:keyPath ] ;
} /* MH_removeObserver */




// Lookup the next implementation of the given selector after the
// default one. Returns nil if no alternate implementation is found.
- (IMP) getImplementationOf:(SEL)lookup after:(IMP)skip
{
    BOOL   found = NO ;

    Class  currentClass = object_getClass( self ) ;

    while ( currentClass )
    {
        // Get the list of methods for this class
        unsigned int  methodCount ;
        Method *      methodList = class_copyMethodList( currentClass, &methodCount ) ;

        // Iterate over all methods
        unsigned int  i ;

        for ( i = 0 ; i < methodCount ; i++ )
        {
            // Look for the selector
            if ( method_getName( methodList [ i ] ) != lookup )
            {
                continue ;
            }

            IMP  implementation = method_getImplementation( methodList [ i ] ) ;

            // Check if this is the "skip" implementation
            if ( implementation == skip )
            {
                found = YES ;
            }
            else
            if ( found )
            {
                // Return the match.
                free( methodList ) ;
                return implementation ;
            }
        }

        // No match found. Traverse up through super class' methods.
        free( methodList ) ;

        currentClass = class_getSuperclass( currentClass ) ;
    }
    return nil ;
} /* getImplementationOf */




- (void *) instanceVariableForKey:(NSString *)aKey
{
    if ( aKey )
    {
        Ivar  ivar = object_getInstanceVariable( self, [ aKey UTF8String ], NULL ) ;
        if ( ivar )
        {
            return (void*)( (char*)self + ivar_getOffset( ivar ) ) ;
        }
    }
    return NULL ;
} /* instanceVariableForKey */




- (void) registerSelfForNotification:(NSString*)notificationName fromObject:(id)obj callback:(SEL)callback
{
    [ [NSNotificationCenter defaultCenter ] addObserver:self
                            selector:callback
                                name:notificationName
                              object:obj ] ;
} /* registerSelfForNotification */




- (void) deregisterSelfForNotification:(NSString*)notificationName fromObject:(id)obj
{
    [ [NSNotificationCenter defaultCenter ] removeObserver:self
                                   name:notificationName
                                 object:obj ] ;
} /* deregisterSelfForNotification */




- (void) propagateValue:(id)value forBinding:(NSString*)binding
{
    NSParameterAssert( binding != nil ) ;

    //WARNING: bindingInfo contains NSNull, so it must be accounted for
    NSDictionary* bindingInfo = [ self infoForBinding:binding ] ;
    if( !bindingInfo )
    {
        return ;        //there is no binding
    }

    //apply the value transformer, if one has been set
    NSDictionary* bindingOptions = [ bindingInfo objectForKey:NSOptionsKey ] ;
    if( bindingOptions )
    {
        NSValueTransformer* transformer = [ bindingOptions valueForKey:NSValueTransformerBindingOption ] ;
        if( !transformer || ( (id)transformer == [ NSNull null ]) )
        {
            NSString* transformerName = [ bindingOptions valueForKey:NSValueTransformerNameBindingOption ] ;
            if( transformerName && ( (id)transformerName != [ NSNull null ]) )
            {
                transformer = [ NSValueTransformer valueTransformerForName:transformerName ] ;
            }
        }

        if( transformer && ( (id)transformer != [ NSNull null ]) )
        {
            if( [ [ transformer class ] allowsReverseTransformation ] )
            {
                value = [ transformer reverseTransformedValue:value ] ;
            }
            else
            {
                NSLog( @"WARNING: binding \"%@\" has value transformer, but it doesn't allow reverse transformations in %s", binding, __PRETTY_FUNCTION__ ) ;
            }
        }
    }

    id  boundObject = [ bindingInfo objectForKey:NSObservedObjectKey ] ;
    if( !boundObject || (boundObject == [ NSNull null ]) )
    {
        NSLog( @"ERROR: NSObservedObjectKey was nil for binding \"%@\" in %s", binding, __PRETTY_FUNCTION__ ) ;
        return ;
    }

    NSString* boundKeyPath = [ bindingInfo objectForKey:NSObservedKeyPathKey ] ;
    if( !boundKeyPath || ( (id)boundKeyPath == [ NSNull null ]) )
    {
        NSLog( @"ERROR: NSObservedKeyPathKey was nil for binding \"%@\" in %s", binding, __PRETTY_FUNCTION__ ) ;
        return ;
    }

    [ boundObject setValue:value forKeyPath:boundKeyPath ] ;
} /* propagateValue */




@end


//
//  NSObject+AssociatedObjects.m
//
//  Created by Andy Matuschak on 8/27/09.
//  Public domain because I love you.
//


@implementation NSObject (AMAssociatedObjects)

- (id) associateValue:(id)value withKey:(void *)key
{
    objc_setAssociatedObject( self, key, value, OBJC_ASSOCIATION_RETAIN ) ;
    return value ;
} /* associateValue */




- (void) weaklyAssociateValue:(id)value withKey:(void *)key
{
    objc_setAssociatedObject( self, key, value, OBJC_ASSOCIATION_ASSIGN ) ;
} /* weaklyAssociateValue */




- (id) associatedValueForKey:(void *)key
{
    return objc_getAssociatedObject( self, key ) ;
} /* associatedValueForKey */




@end


@interface AMObserverTrampoline : NSObject
{
    @public
    __weak id         observee ;
    NSString *        keyPath ;
    AMBlockTask       task ;
    NSOperationQueue *queue ;
    dispatch_once_t   cancellationPredicate ;
}

- (AMObserverTrampoline *) initObservingObject:(id)obj keyPath:(NSString *)keyPath onQueue:(NSOperationQueue *)queue task:(AMBlockTask)task ;
- (void)                   cancelObservation ;
@end

@implementation AMObserverTrampoline

static NSString *AMObserverTrampolineContext = @"AMObserverTrampolineContext" ;

- (AMObserverTrampoline *) initObservingObject:(id)obj keyPath:(NSString *)newKeyPath onQueue:(NSOperationQueue *)newQueue task:(AMBlockTask)newTask
{
    if ( !(self = [ super init ]) ) { return nil ; }
    task     = [ newTask copy ] ;
    keyPath  = [ newKeyPath copy ] ;
    queue    = [ newQueue retain ] ;
    observee = obj ;
    cancellationPredicate = 0 ;
    [ observee addObserver:self forKeyPath:keyPath options:0 context:AMObserverTrampolineContext ] ;
    return self ;
} /* initObservingObject */




- (void) observeValueForKeyPath:(NSString *)aKeyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ( context == AMObserverTrampolineContext )
    {
        if ( queue )
        {
            [ queue addOperationWithBlock:^{ task (object, change) ;
              } ] ;
        }
        else
        {
            task( object, change ) ;
        }
    }
} /* observeValueForKeyPath */




- (void) cancelObservation
{
    dispatch_once( &cancellationPredicate, ^{
                       [ observee removeObserver:self forKeyPath:keyPath ] ;
                       observee = nil ;
                   } ) ;
} /* cancelObservation */




- (void) dealloc
{
    [ self cancelObservation ] ;
    [ task release ] ;
    [ keyPath release ] ;
    [ queue release ] ;
    [ super dealloc ] ;
} /* dealloc */




@end

static NSString * AMObserverMapKey = @"org.andymatuschak.observerMap" ;
static dispatch_queue_t  AMObserverMutationQueue = NULL ;

static dispatch_queue_t  AMObserverMutationQueueCreatingIfNecessary ()
{
    static dispatch_once_t  queueCreationPredicate = 0 ;
    dispatch_once( &queueCreationPredicate, ^{
                       AMObserverMutationQueue = dispatch_queue_create ("org.andymatuschak.observerMutationQueue", 0) ;
                   } ) ;
    return AMObserverMutationQueue ;
} /* AMObserverMutationQueueCreatingIfNecessary */




@implementation NSObject (AMBlockObservation)

- (AMBlockToken *) addObserverForKeyPath:(NSString *)keyPath task:(AMBlockTask)task
{
    return [ self addObserverForKeyPath:keyPath onQueue:nil task:task ] ;
} /* addObserverForKeyPath */




- (AMBlockToken *) addObserverForKeyPath:(NSString *)keyPath onQueue:(NSOperationQueue *)queue task:(AMBlockTask)task
{
    AMBlockToken *token = [ [ NSProcessInfo processInfo ] globallyUniqueString ] ;

    dispatch_sync( AMObserverMutationQueueCreatingIfNecessary(), ^{
                       NSMutableDictionary *dict = objc_getAssociatedObject (self, AMObserverMapKey) ;
                       if ( !dict )
                       {
                           dict = [ [ NSMutableDictionary alloc ] init ] ;
                           objc_setAssociatedObject (self, AMObserverMapKey, dict, OBJC_ASSOCIATION_RETAIN) ;
                           [ dict release ] ;
                       }
                       AMObserverTrampoline *trampoline = [ [ AMObserverTrampoline alloc ] initObservingObject:self keyPath:keyPath onQueue:queue task:task ] ;
                       [ dict setObject:trampoline forKey:token ] ;
                       [ trampoline release ] ;
                   } ) ;
    return token ;
} /* addObserverForKeyPath */




- (void) invokeChangeTaskForBlockToken:(AMBlockToken *)token
{
    dispatch_sync( AMObserverMutationQueueCreatingIfNecessary(), ^{
                       NSMutableDictionary *observationDictionary = objc_getAssociatedObject (self, AMObserverMapKey) ;
                       AMObserverTrampoline *trampoline = [ observationDictionary objectForKey:token ] ;
                       if ( !trampoline )
                       {
                           NSLog (@"[NSObject(AMBlockObservation) invokeChangeTaskForBlockToken]: Ignoring attempt to invoke non-existent observer on %@ for token %@.", self, token) ;
                           return ;
                       }

                       trampoline->task (nil, nil) ;
                   } ) ;
} /* invokeChangeTaskForBlockToken */




- (void) removeObserverWithBlockToken:(AMBlockToken *)token
{
    if ( token != nil )
    {
        dispatch_sync( AMObserverMutationQueueCreatingIfNecessary(), ^{
                           NSMutableDictionary *observationDictionary = objc_getAssociatedObject (self, AMObserverMapKey) ;
                           AMObserverTrampoline *trampoline = [ observationDictionary objectForKey:token ] ;
                           if ( !trampoline )
                           {
                               return ;
                           }


                           [ trampoline cancelObservation ] ;
                           [ observationDictionary removeObjectForKey:token ] ;

                           // Due to a bug in the obj-c runtime, this dictionary does not get cleaned up on release when running without GC.
                           if ( [ observationDictionary count ] == 0 )
                               objc_setAssociatedObject (self, AMObserverMapKey, nil, OBJC_ASSOCIATION_RETAIN) ;
                       } ) ;
    }
} /* removeObserverWithBlockToken */




@end
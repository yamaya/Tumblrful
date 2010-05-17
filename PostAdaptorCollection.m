/**
 * @file PostAdaptorCollection.m
 * @brief PostAdaptorCollection implementation
 * @author Masayuki YAMAYA
 * @date 2008-03-07
 */
#import "PostAdaptorCollection.h"
#import "Log.h"

//#define V(format, ...)	Log(format, __VA_ARGS__)
#define V(format, ...)

#pragma mark -
@interface PostAdaptorCollection (Private)
+ (NSMutableArray*) sharedInstance;
@end

#pragma mark -
@implementation PostAdaptorCollection
/**
 *
 */
+ (void) add:(Class)postClass
{
	NSMutableArray* array = [PostAdaptorCollection sharedInstance];
	[array addObject:postClass];
}

/**
 *
 */
+ (NSEnumerator*) enumerator
{
	return [[PostAdaptorCollection sharedInstance] objectEnumerator];
}

+ (NSUInteger) count
{
	return [[PostAdaptorCollection sharedInstance] count];
}
@end

#pragma mark -
@implementation PostAdaptorCollection (Private)
+ (NSMutableArray*) sharedInstance
{
	static NSMutableArray* array = nil;
	if (array == nil) {
		array = [[[NSMutableArray alloc] init] retain];
	}
	return array;
}
@end

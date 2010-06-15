/**
 * @file PostAdaptorCollection.m
 * @brief PostAdaptorCollection class implementation
 * @author Masayuki YAMAYA
 * @date 2008-03-07
 */
#import "PostAdaptorCollection.h"
#import "DebugLog.h"

#pragma mark -
@interface PostAdaptorCollection ()
+ (NSMutableArray *)sharedInstance;
@end

#pragma mark -
@implementation PostAdaptorCollection
/**
 *
 */
+ (void)add:(Class)postClass
{
	NSMutableArray* array = [PostAdaptorCollection sharedInstance];
	[array addObject:postClass];
}

+ (NSEnumerator *)enumerator
{
	return [[PostAdaptorCollection sharedInstance] objectEnumerator];
}

+ (NSUInteger)count
{
	return [[PostAdaptorCollection sharedInstance] count];
}

+ (NSMutableArray *)sharedInstance
{
	static NSMutableArray* array = nil;
	if (array == nil) {
		array = [[[NSMutableArray alloc] init] retain];
	}
	return array;
}
@end

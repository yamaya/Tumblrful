/**
 * @file PostAdaptorCollection.h
 * @brief PostAdaptorCollection declaration
 * @author Masayuki YAMAYA
 * @date 2008-03-07
 */
#import <Foundation/Foundation.h>

@interface PostAdaptorCollection : NSObject
+ (void) add:(Class)postClass;
+ (NSEnumerator*) enumerator;
+ (NSUInteger) count;
@end

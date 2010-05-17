/**
 * @file PostAdaptor.h
 * @brief PostAdaptor declaration.
 *          Deliverer と Post をつなぐ
 * @author Masayuki YAMAYA
 * @date 2008-03-07
 */
#import "Anchor.h"
#import "PostCallback.h"
#import <Foundation/Foundation.h>

#ifndef FIX20080412
#define FIX20080412
#endif

/**
 * PostAdaptor abstract class
 */
@interface PostAdaptor : NSObject
{
	id<PostCallback> callback_;
	BOOL private_; /* not implemented yet */
}
+ (NSString*) titleForMenuItem;
+ (BOOL) enableForMenuItem;
- (id) initWithCallback:(id<PostCallback>)callback;
- (id) initWithCallback:(id<PostCallback>)callback private:(BOOL)private;
- (void) dealloc;

- (id<PostCallback>) callback;
- (void) setCallback:(id<PostCallback>)callback;
- (BOOL) private;
- (void) setPrivate:(BOOL)private;

- (void) callbackWith:(NSString*)response;
- (void) callbackWithError:(NSError*)error;
- (void) callbackWithException:(NSException*)exception;

- (void) postLink:(Anchor*)anchor description:(NSString*)description;
- (void) postQuote:(Anchor*)anchor quote:(NSString*)quote;
/* througURL は [anchor URL] を想定 */
- (void) postPhoto:(Anchor*)anchor image:(NSString*)imageURL caption:(NSString*)caption;
- (void) postVideo:(Anchor*)anchor embed:(NSString*)embed caption:(NSString*)caption;
#ifdef FIX20080412
- (NSObject*) postEntry:(NSDictionary*)params;
#else
- (NSObject*) postEntry:(NSString*)entryID;
#endif
@end

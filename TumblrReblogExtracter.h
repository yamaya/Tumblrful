/**
 * @file TumblrReblogExtracter.h
 * @brief TumblrReblogExtracter declaration
 * @author Masayuki YAMAYA
 * @date 2008-04-23
 */
#include <Foundation/Foundation.h>

@interface TumblrReblogExtracter : NSObject
{
	id continuation_;
	NSMutableData* responseData_;
	NSString* endpoint_;
}
- (id)initWith:(id)continuation;
- (void)dealloc;
- (void)extract:(NSString*)pid key:(NSString*)rk;
@end

/**
 * @file TumblrPostAdaptor.h
 * @brief TumblrPostAdaptor declaration
 * @author Masayuki YAMAYA
 * @date 2008-03-07
 *
 * Deliverer と TumblrPost をつなぐ
 */
#import "PostAdaptor.h"

@interface TumblrPostAdaptor : PostAdaptor
{
	BOOL queuing_;	/**< queuing post */
}
- (void) postLink:(Anchor*)anchor description:(NSString*)description;
- (void) postQuote:(Anchor*)anchor quote:(NSString*)quote;
- (void) postPhoto:(Anchor*)anchor image:(NSString*)imageURL caption:(NSString*)caption;
- (void) postVideo:(Anchor*)anchor embed:(NSString*)embed caption:(NSString*)caption;
- (NSObject*) postEntry:(NSDictionary*)params;

- (void) setQueueing:(BOOL)queuing;
- (BOOL) queuing;
@end

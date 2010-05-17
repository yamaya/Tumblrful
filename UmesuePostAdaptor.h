/**
 * @file UmesuePostAdaptor.h
 * @brief UmesuePostAdaptor declaration
 * @author Masayuki YAMAYA
 * @date 2008-04-19
 *
 * Deliverer と UmesuePost をつなぐ
 */
#import "PostAdaptor.h"

@interface UmesuePostAdaptor : PostAdaptor
+ (NSString*) titleForMenuItem;
+ (BOOL) enableForMenuItem;
- (void) postLink:(Anchor*)anchor description:(NSString*)description;
- (void) postQuote:(Anchor*)anchor quote:(NSString*)quote;
- (void) postPhoto:(Anchor*)anchor image:(NSString*)imageURL caption:(NSString*)caption;
- (void) postVideo:(Anchor*)anchor embed:(NSString*)embed caption:(NSString*)caption;
- (NSObject*) postEntry:(NSDictionary*)params;
@end

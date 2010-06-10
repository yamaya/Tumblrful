/**
 * @file DeliciousPostAdaptor.h
 * @brief DeliciousPostAdaptor declaration
 * @author Masayuki YAMAYA
 * @date 2008-03-07
 *
 * Deliverer と DeliciousPost をつなぐ
 */
#import "PostAdaptor.h"

/**
 * PostAdaptor for delicious
 */
@interface DeliciousPostAdaptor : PostAdaptor

+ (NSString *)titleForMenuItem;

+ (BOOL)enableForMenuItem;

- (void)postLink:(Anchor*)anchor description:(NSString*)description;

- (void)postQuote:(NSString *)quote source:(NSString *)source;

- (void)postPhoto:(NSString *)source caption:(NSString *)caption throughURL:(NSString *)throughURL;

- (void)postVideo:(Anchor*)anchor embed:(NSString*)embed caption:(NSString*)caption;

- (NSObject *)postEntry:(NSDictionary*)params;
@end

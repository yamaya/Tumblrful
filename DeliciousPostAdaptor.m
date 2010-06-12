/**
 * @file DeliciousPostAdaptor.m
 * @brief DeliciousPostAdaptor implementation
 * @author Masayuki YAMAYA
 * @date 2008-03-07
 *
 * Deliverer と DeliciousPost をつなぐ
 */
#import "DeliciousPostAdaptor.h"
#import "DeliciousPost.h"
#import "DebugLog.h"

#define MAX_DESCRIPTION (256)

#pragma mark -
@interface DeliciousPostAdaptor ()
- (void)postTo:(NSDictionary *)params;
@end

#pragma mark -
@implementation DeliciousPostAdaptor
/**
 */
+ (NSString *)titleForMenuItem
{
	return @"del.icio.us";
}

+ (BOOL)enableForMenuItem
{
	return [DeliciousPost isEnabled];
}

- (void)postLink:(Anchor *)anchor description:(NSString *)description
{
	if ([DeliciousPost isEnabled]) {

		if ([description length] > MAX_DESCRIPTION) {
			description = [description stringByPaddingToLength:(MAX_DESCRIPTION - 3) withString:@"." startingAtIndex:0];
		}

		NSMutableDictionary* params = [[[NSMutableDictionary alloc] init] autorelease];
		[params setValue:anchor.URL forKey:@"url"];
		[params setValue:anchor.title forKey:@"description"];
		[params setValue:description forKey:@"extended"];
#if 0
		[params setValue:"one two three" forKey:@"tags"];
		[params setValue:"CCYY-MM-DDThh:mm:ssZ" forKey:@"dt"];
		[params setValue:"no" forKey:@"replace"];
#endif
		[self postTo:params];
	}
}

- (void)postQuote:(NSString *)quote source:(NSString *)source;
{
	[self postLink:[Anchor anchorWithHTML:source] description:quote];
}

- (void)postPhoto:(NSString *)source caption:(NSString *)caption throughURL:(NSString *)throughURL
{
#pragma unused (source, caption, throughURL)
	// do-nothing
}

- (void) postVideo:(Anchor*)anchor embed:(NSString*)embed caption:(NSString*)caption
{
#pragma unused (anchor, embed, caption)
	[self postLink:anchor description:caption];
}

- (void)postEntry:(NSDictionary *)params
{
#pragma unused (params)
	// do-nothing
}

- (void)postTo:(NSDictionary *)params
{
	@try {
		// del.icio.us へポストするオブジェクトを生成する
		DeliciousPost * delicious = [[DeliciousPost alloc] initWithCallback:callback_];

		// リクエストパラメータを構築する
		NSMutableDictionary * requestParams = [delicious createMinimumRequestParams];
		[requestParams addEntriesFromDictionary:params];
		D(@"requestParams: %@", [requestParams description]);

		// del.icio.us へポストする
		[delicious postWith:requestParams];
	}
	@catch (NSException * e) {
		D0([e description]);
		[self callbackWithException:e];
	}
}
@end

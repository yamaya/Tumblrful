/**
 * @file InstapaperPostAdaptor.m
 */
#import "InstapaperPostAdaptor.h"
#import "InstapaperPost.h"
#import "NSString+Tumblrful.h"
#import "DebugLog.h"

@implementation InstapaperPostAdaptor

#pragma mark -
#pragma mark Override Methods

+ (NSString *)titleForMenuItem
{
	return @"Instapaper";
}

+ (BOOL)enableForMenuItem
{
	return [InstapaperPost enabled];
}

- (void)postLink:(Anchor *)anchor description:(NSString *)description
{
	if (![InstapaperPost enabled]) return;

	@try {
		// Instapaperへポストするオブジェクトを生成する
		InstapaperPost * instapaper = [[InstapaperPost alloc] initWithCallback:callback_];

		// リクエストパラメータを構築する
		NSMutableDictionary * params = [instapaper createMinimumRequestParams];
		[params setObject:anchor.URL forKey:@"url"];
		if (description != nil) [params setObject:description forKey:@"selection"];	// no HTML
		D0([params description]);

		// ポストする
		[instapaper postWith:params];
	}
	@catch (NSException * e) {
		D0([e description]);
		[self callbackWithException:e];
	}
}

- (void)postQuote:(NSString *)quote source:(NSString *)source;
{
	[self postLink:[Anchor anchorWithHTML:source] description:quote];
}

- (void)postPhoto:(NSString *)source caption:(NSString *)caption throughURL:(NSString *)throughURL
{
#pragma unused (source, caption, throughURL)
	D0(caption);
	D(@"striped=%@", [caption stripHTMLTags:nil]);

	[self postLink:[Anchor anchorWithHTML:caption] description:[caption stripHTMLTags:nil]];
}

- (void)postVideo:(NSString *)embed caption:(NSString*)caption
{
#pragma unused (embed, caption)
	// do-nothing
}

- (void)postEntry:(NSDictionary *)params
{
#pragma unused (params)
	// do-nothing
}
@end

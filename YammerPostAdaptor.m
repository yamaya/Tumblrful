/**
 * @file YammerPostAdaptor.m
 */
#import "YammerPostAdaptor.h"
#import "YammerPost.h"
#import "NSString+Tumblrful.h"
#import "DebugLog.h"

@implementation YammerPostAdaptor

#pragma mark -
#pragma mark Override Methods

+ (NSString *)titleForMenuItem
{
	return @"Yammer";
}

+ (BOOL)enableForMenuItem
{
	return [YammerPost enabled];
}

- (void)postLink:(Anchor *)anchor description:(NSString *)description
{
	if (![YammerPost enabled]) return;

	@try {
		NSMutableString * body = [NSMutableString string];
		if (description != nil && [description length] > 0)
			[body appendFormat:@"“%@” ", description];
		[body appendFormat:@"[%@](%@)", anchor.title, anchor.URL];

		// Yammerへポストするオブジェクトを生成する
		YammerPost * yammer = [[YammerPost alloc] initWithCallback:callback_];

		// リクエストパラメータを構築する
		NSMutableDictionary * params = [yammer createMinimumRequestParams];
		[params setObject:body forKey:@"body"];
		D0([params description]);

		// ポストする
		[yammer postWith:params];
	}
	@catch (NSException * e) {
		D0([e description]);
		[self callbackWithException:e];
	}
}

- (void)postQuote:(NSString *)quote source:(NSString *)source;
{
	D0(quote);
	D0(source);
	[self postLink:[Anchor anchorWithHTML:source] description:quote];
}

- (void)postPhoto:(NSString *)source caption:(NSString *)caption throughURL:(NSString *)throughURL
{
#pragma unused (source, caption, throughURL)
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

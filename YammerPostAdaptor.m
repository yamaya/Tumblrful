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

+ (BOOL)enableForMenuItem:(NSString *)postType
{
	static NSArray * enablePostTypes = nil;

	if ([YammerPost enabled]) {
		if (enablePostTypes == nil) {
			enablePostTypes = [NSArray arrayWithObjects:
				  [NSString stringWithPostType:LinkPostType]
				, [NSString stringWithPostType:QuotePostType]
				, nil];
			[enablePostTypes retain];
		}

		postType = [postType capitalizedString];
		return [enablePostTypes indexOfObject:postType] != NSNotFound;
	}
	return NO;
}

- (void)postLink:(Anchor *)anchor description:(NSString *)description
{
	if (![YammerPost enabled]) return;

	@try {
		NSMutableString * body = [NSMutableString string];
		if (description != nil && [description length] > 0)
			[body appendFormat:@"%@ ", description];
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
	[self postLink:[Anchor anchorWithHTML:source] description:quote];
}

- (void)postPhoto:(NSString *)source caption:(NSString *)caption throughURL:(NSString *)throughURL image:(NSImage *)image
{
#pragma unused (source, caption, throughURL, image)
	// do-nothing
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

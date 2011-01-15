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
#import "NSString+Tumblrful.h"
#import "DebugLog.h"

#define MAX_DESCRIPTION (256)

@interface DeliciousPostAdaptor ()
@end

@implementation DeliciousPostAdaptor

+ (NSString *)titleForMenuItem
{
	return @"delicious";
}

+ (BOOL)enableForMenuItem:(NSString *)postType
{
	static NSArray * enablePostTypes = nil;

	if ([DeliciousPost enabled]) {
		if (enablePostTypes == nil) {
			enablePostTypes = [NSArray arrayWithObjects:
				  [NSString stringWithPostType:LinkPostType]
				, [NSString stringWithPostType:QuotePostType]
				, [NSString stringWithPostType:PhotoPostType]
				, [NSString stringWithPostType:VideoPostType]
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
	if (![DeliciousPost enabled]) return;

	@try {
		if ([description length] > MAX_DESCRIPTION) {
			description = [description stringByPaddingToLength:(MAX_DESCRIPTION - 3) withString:@"." startingAtIndex:0];
		}

		// delicious へポストするオブジェクトを生成する
		DeliciousPost * delicious = [[DeliciousPost alloc] initWithCallback:callback_];

		// リクエストパラメータを構築する
		NSMutableDictionary * params = [delicious createMinimumRequestParams];
		[params setValue:anchor.URL forKey:@"url"];
		[params setValue:anchor.title forKey:@"description"];
		[params setValue:description forKey:@"extended"];
		D(@"params: %@", [params description]);

		// ポストする
		[delicious postWith:params];
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
#pragma unused (source, throughURL, image)
	[self postLink:[Anchor anchorWithHTML:caption] description:[caption stripHTMLTags:nil]];
}

- (void)postVideo:(NSString *)embed caption:(NSString*)caption
{
#pragma unused (embed, caption)
	[self postLink:[Anchor anchorWithHTML:caption] description:[caption stripHTMLTags:nil]];
}

- (void)postEntry:(NSDictionary *)params
{
#pragma unused (params)
	// do-nothing
}
@end

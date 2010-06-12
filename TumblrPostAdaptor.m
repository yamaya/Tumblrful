/**
 * @file TumblrPostAdaptor.m
 * @brief TumblrPostAdaptor implementation
 * @author Masayuki YAMAYA
 * @date 2008-03-07
 */
#import "TumblrPostAdaptor.h"
#import "TumblrPost.h"
#import "DebugLog.h"

#pragma mark -
@interface TumblrPostAdaptor ()
- (void)postWithType:(NSString *)type withParams:(NSDictionary *)params;
@end

#pragma mark -
@implementation TumblrPostAdaptor

- (void)postLink:(Anchor *)anchor description:(NSString *)description
{
	[self postWithType:@"link" withParams:[NSDictionary dictionaryWithObjectsAndKeys:anchor.URL, @"url", anchor.title, @"name", description, @"description", nil]];
}

- (void)postQuote:(NSString *)quote source:(NSString *)source;
{
	[self postWithType:@"quote" withParams:[NSMutableDictionary dictionaryWithObjectsAndKeys:quote, @"quote", source, @"source", nil]];
}

- (void)postPhoto:(NSString *)source caption:(NSString *)caption throughURL:(NSString *)throughURL
{
	[self postWithType:@"photo" withParams:[NSMutableDictionary dictionaryWithObjectsAndKeys:source, @"source", caption, @"caption", throughURL, @"click-through-url", nil]];
}

- (void)postVideo:(NSString *)embed caption:(NSString*)caption
{
	[self postWithType:@"video" withParams:[NSMutableDictionary dictionaryWithObjectsAndKeys:embed, @"embed", caption, @"caption", nil]];
}

- (void)postEntry:(NSDictionary *)params
{
	[self postWithType:@"reblog" withParams:[NSMutableDictionary dictionaryWithObjectsAndKeys:[params objectForKey:@"pid"], @"pid", [params objectForKey:@"rk"], @"rk", nil]];
}

- (void)postWithType:(NSString *)type withParams:(NSDictionary *)params
{
	@try {
		// Tumblrへポストするオブジェクトを生成する
		TumblrPost * tumblr = [[TumblrPost alloc] initWithCallback:callback_];
		[tumblr retain];

		// プライベートとキューイングの設定をしておく
		tumblr.privated = self.privated;
		tumblr.queuingEnabled = self.queuingEnabled;

		// リクエストパラメータを構築する
		NSMutableDictionary * requestParams = [tumblr createMinimumRequestParams];
		[requestParams setObject:type forKey:@"type"];
		[requestParams addEntriesFromDictionary:params];

		// Tumblrへポストする
		[tumblr postWith:requestParams];
	}
	@catch (NSException * e) {
		D0([e description]);
		[self callbackWithException:e];
	}
}
@end

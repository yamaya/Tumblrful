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
- (void)postTo:(NSString *)type params:(NSDictionary *)params;
@end

#pragma mark -
@implementation TumblrPostAdaptor
- (void)postLink:(Anchor *)anchor description:(NSString *)description
{
	NSMutableDictionary* params = [[[NSMutableDictionary alloc] init] autorelease];
	[params setValue:[anchor URL] forKey:@"url"];
	[params setValue:[anchor title] forKey:@"name"];
	[params setValue:description forKey:@"description"];

	[self postTo:@"link" params:params];
}

- (void)postQuote:(NSString *)quote source:(NSString *)source;
{
	[self postTo:@"quote" params:[NSMutableDictionary dictionaryWithObjectsAndKeys:quote, @"quote", source, @"source", nil]];
}

- (void)postPhoto:(NSString *)source caption:(NSString *)caption throughURL:(NSString *)throughURL
{
	[self postTo:@"photo" params:[NSMutableDictionary dictionaryWithObjectsAndKeys:source, @"source", caption, @"caption", throughURL, @"click-through-url", nil]];
}

- (void) postVideo:(Anchor*)anchor embed:(NSString*)embed caption:(NSString*)caption
{
	NSMutableDictionary* params = [[[NSMutableDictionary alloc] init] autorelease];
	[params setValue:embed forKey:@"embed"];
	[params setValue:[anchor title] forKey:@"title"];
	[params setValue:caption forKey:@"caption"];

	[self postTo:@"video" params:params];
}

- (NSObject *)postEntry:(NSDictionary *)params
{
	@try {
		// Tumblrへポストするオブジェクトを生成する
		TumblrPost * tumblr = [[TumblrPost alloc] initWithCallback:callback_];

		// Reblog する
		return [tumblr reblog:[params objectForKey:@"pid"] key:[params objectForKey:@"rk"]];
	}
	@catch (NSException * e) {
		D0([e description]);
		[self callbackWithException:e];
	}
	return nil;
}

- (void)setQueueing:(BOOL)queuing
{
	queuing_ = queuing;
}

- (BOOL)queuing
{
	return queuing_;
}

- (void)postTo:(NSString *)type params:(NSDictionary *)params
{
	@try {
		// Tumblrへポストするオブジェクトを生成する
		TumblrPost * tumblr = [[TumblrPost alloc] initWithCallback:callback_];
		[tumblr retain];

		// プライベートとキューイングの設定をしておく
		[tumblr setPrivate:private_];
		[tumblr setQueueing:queuing_];

		// リクエストパラメータを構築する
		NSMutableDictionary * requestParams = [tumblr createMinimumRequestParams];
		[requestParams setValue:type forKey:@"type"];
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

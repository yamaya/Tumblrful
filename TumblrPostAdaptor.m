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
@interface TumblrPostAdaptor (Private)
- (void) postTo:(NSString*)type params:(NSDictionary*)params;
@end

#pragma mark -
@implementation TumblrPostAdaptor
/**
 */
- (void) postLink:(Anchor*)anchor description:(NSString*)description
{
	NSMutableDictionary* params = [[[NSMutableDictionary alloc] init] autorelease];
	[params setValue:[anchor URL] forKey:@"url"];
	[params setValue:[anchor title] forKey:@"name"];
	[params setValue:description forKey:@"description"];

	[self postTo:@"link" params:params];
}

/**
 */
- (void) postQuote:(Anchor*)anchor quote:(NSString*)quote;
{
	NSMutableDictionary* params = [[[NSMutableDictionary alloc] init] autorelease];
	[params setValue:quote forKey:@"quote"];
	[params setValue:[anchor tag] forKey:@"source"];

	[self postTo:@"quote" params:params];
}

/**
 */
- (void) postPhoto:(Anchor*)anchor image:(NSString*)imageURL caption:(NSString*)caption
{
	D(@"caption:%@", caption);

	NSMutableDictionary* params = [[[NSMutableDictionary alloc] init] autorelease];
	[params setValue:imageURL forKey:@"source"];
	[params setValue:caption forKey:@"caption"];
	[params setValue:[anchor URL] forKey:@"click-through-url"];

	[self postTo:@"photo" params:params];
}

/**
 */
- (void) postVideo:(Anchor*)anchor embed:(NSString*)embed caption:(NSString*)caption
{
	NSMutableDictionary* params = [[[NSMutableDictionary alloc] init] autorelease];
	[params setValue:embed forKey:@"embed"];
	[params setValue:[anchor title] forKey:@"title"];
	[params setValue:caption forKey:@"caption"];

	[self postTo:@"video" params:params];
}

/**
 * エントリのポスト(Reblog等)
 */
- (NSObject*) postEntry:(NSDictionary*)params
{
	@try {
		/* Tumblrへポストするオブジェクトを生成する */
		TumblrPost* tumblr = [[TumblrPost alloc] initWithCallback:callback_];

		/* Reblog する */
		return [tumblr reblog:[params objectForKey:@"pid"] key:[params objectForKey:@"rk"]];
	}
	@catch (NSException* exception) {
		[self callbackWithException:exception];
	}
	return nil;
}

- (void) setQueueing:(BOOL)queuing
{
	queuing_ = queuing;
}

- (BOOL) queuing
{
	return queuing_;
}

@end

#pragma mark -
@implementation TumblrPostAdaptor (Private)
/**
 * post to Tumblr
 */
- (void) postTo:(NSString*)type params:(NSDictionary*)params
{
	@try {
		/* Tumblrへポストするオブジェクトを生成する */
		TumblrPost* tumblr = [[TumblrPost alloc] initWithCallback:callback_];
		[tumblr retain];

		// プライベートとキューイングの設定をしておく
		[tumblr setPrivate:private_];
		[tumblr setQueueing:queuing_];

		/* リクエストパラメータを構築する */
		NSMutableDictionary* requestParams = [tumblr createMinimumRequestParams];
		[requestParams setValue:type forKey:@"type"];
		[requestParams addEntriesFromDictionary:params];

		/* Tumblrへポストする */
		[tumblr postWith:requestParams];
	}
	@catch (NSException* e) {
		[self callbackWithException:e];
	}
}
@end

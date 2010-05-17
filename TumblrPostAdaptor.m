/**
 * @file TumblrPostAdaptor.m
 * @brief TumblrPostAdaptor implementation
 * @author Masayuki YAMAYA
 * @date 2008-03-07
 */
#import "TumblrPostAdaptor.h"
#import "TumblrPost.h"

//#define V(format, ...)	Log(format, __VA_ARGS__)
#define V(format, ...)

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

	V(@"TumblrPostAdaptor.postQuote: %@", [params description]);
	[self postTo:@"quote" params:params];
}

/**
 */
- (void) postPhoto:(Anchor*)anchor image:(NSString*)imageURL caption:(NSString*)caption
{
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
#ifdef FIX20080412
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
#else
- (NSObject*) postEntry:(NSString*)entryID
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
#endif
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

		/* リクエストパラメータを構築する */
		NSMutableDictionary* requestParams = [tumblr createMinimumRequestParams];
		[requestParams setValue:type forKey:@"type"];
		[requestParams addEntriesFromDictionary:params];
		V(@"requestParams: %@", [requestParams description]);

		/* Tumblrへポストする */
		[tumblr postWith:requestParams];
	}
	@catch (NSException* e) {
		[self callbackWithException:e];
	}
}
@end

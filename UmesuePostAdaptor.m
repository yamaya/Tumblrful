/**
 * @file UmesuePostAdaptor.m
 * @brief UmesuePostAdaptor class implementation
 * @author Masayuki YAMAYA
 * @date 2008-04-19
 */
#import "UmesuePostAdaptor.h"
#import "UmesuePost.h"
#import "DebugLog.h"

#pragma mark -
@interface UmesuePostAdaptor ()
- (void)postWithType:(NSString *)type withParams:(NSDictionary *)params;
@end

#pragma mark -
@implementation UmesuePostAdaptor

+ (NSString *)titleForMenuItem
{
	return @"Umesue";
}

+ (BOOL)enableForMenuItem
{
	return [UmesuePost isEnabled];
}

- (void)postLink:(Anchor *)anchor description:(NSString *)description
{
	if (![UmesuePost isEnabled]) return;

	[self postWithType:@"LinkPost" withParams:[NSDictionary dictionaryWithObjectsAndKeys:anchor.title, @"name", anchor.URL, @"url", description, @"note", nil]];
}

- (void)postQuote:(NSString *)quote source:(NSString *)source;
{
	if (![UmesuePost isEnabled]) return;

	[self postWithType:@"QuotePost" withParams:[NSDictionary dictionaryWithObjectsAndKeys:quote, @"quote", source, @"source", nil]];
}

- (void)postPhoto:(NSString *)source caption:(NSString *)caption throughURL:(NSString *)throughURL
{
	if (![UmesuePost isEnabled]) return;

	[self postWithType:@"PhotoPost" withParams:[NSDictionary dictionaryWithObjectsAndKeys:source, @"image", caption, @"caption", throughURL, @"link", nil]];
}

- (void)postVideo:(Anchor *)anchor embed:(NSString *)embed caption:(NSString *)caption
{
#pragma unused (anchor)
	if (![UmesuePost isEnabled]) return;

	[self postWithType:@"VideoPost" withParams:[NSDictionary dictionaryWithObjectsAndKeys:embed, @"url", caption, @"caption", nil]];
}

- (void)postEntry:(NSDictionary *)params
{
	if (![UmesuePost isEnabled]) return;

	TumblrReblogExtractor * extractor = [[TumblrReblogExtractor alloc] initWithDelegate:self];
	[extractor startWithPostID:[params objectForKey:@"pid"] withReblogKey:[params objectForKey:@"rk"]];
}

- (void)extractor:(TumblrReblogExtractor *)extractor didFinishExtract:(NSDictionary *)contents
{
#pragma unused (extractor)
	D(@"extract: contents=%@", SafetyDescription(contents));

	Class contentsClass = [contents class];
	if ([contentsClass isSubclassOfClass:[NSString class]]) {
		[self callbackWith:(NSString*)contents];
	}
	else if ([contentsClass isSubclassOfClass:[NSDictionary class]]) {
		NSString * type = [contents objectForKey:@"type"];
		if ([type isEqualToString:@"link"]) {
			[self postWithType:@"LinkPost" withParams:[NSDictionary dictionaryWithObjectsAndKeys:[contents objectForKey:@"post[one]"], @"name", [contents objectForKey:@"post[two]"], @"url", [contents objectForKey:@"post[three]"], @"note", nil]];
		}
		else if ([type isEqualToString:@"photo"]) {
			[self postWithType:@"PhotoPost" withParams:[NSDictionary dictionaryWithObjectsAndKeys:[contents objectForKey:@"imgsrc"], @"imgsrc", [contents objectForKey:@"post[two]"], @"caption", [contents objectForKey:@"post[three]"], @"link", nil]];
		}
		else if ([type isEqualToString:@"quote"]) {
			[self postWithType:@"QuotePost" withParams:[NSDictionary dictionaryWithObjectsAndKeys:[contents objectForKey:@"post[one]"], @"quote" ,[contents objectForKey:@"post[two]"], @"source", nil]];
		}
		else if ([type isEqualToString:@"regular"]) {
			[self postWithType:@"TextPost" withParams:[NSDictionary dictionaryWithObjectsAndKeys:[contents objectForKey:@"post[one]"], @"title", [contents objectForKey:@"post[two]"], @"body", nil]];
		}
		else if ([type isEqualToString:@"video"]) {
			[self postWithType:@"VideoPost" withParams:[NSDictionary dictionaryWithObjectsAndKeys:[contents objectForKey:@"post[one]"], @"url", [contents objectForKey:@"post[two]"], @"caption", nil]];
		}
		else {
			[self callbackWith:[NSString stringWithFormat:@"\"%@\" post not supported yet", type]];
		}
	}
}

- (void)extractor:(TumblrReblogExtractor *)extractor didFailExtractWithError:(NSError *)error
{
#pragma unused (extractor)
	[self callbackWithError:error];
}

- (void)extractor:(TumblrReblogExtractor *)extractor didFailExtractWithException:(NSException *)exception
{
#pragma unused (extractor, exception)
	[self callbackWithException:exception];
}

- (void)postWithType:(NSString *)type withParams:(NSDictionary *)params
{
	@try {
		UmesuePost * umesue = [[UmesuePost alloc] initWithCallback:callback_];

		NSMutableDictionary * requestParams = [umesue createMinimumRequestParams];
		[requestParams setObject:type forKey:@"type"];
		[requestParams addEntriesFromDictionary:params];

		[umesue postWith:requestParams];
	}
	@catch (NSException * e) {
		D0([e description]);
		[self callbackWithException:e];
	}
}
@end

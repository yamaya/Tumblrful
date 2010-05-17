/**
 * @file UmesuePostAdaptor.m
 * @brief UmesuePostAdaptor implementation
 * @author Masayuki YAMAYA
 * @date 2008-04-19
 *
 * Deliverer と UmesuePost をつなぐ
 */
#import "UmesuePostAdaptor.h"
#import "UmesuePost.h"
#import "TumblrReblogExtracter.h"
#import "Log.h"
// /System/Library/Frameworks/WebKit.framework/Headers/DOMHTMLAnchorElement.h

//#define V(format, ...)	Log(format, __VA_ARGS__)
#define V(format, ...)

#pragma mark -
@interface UmesuePostAdaptor (Private)
- (void) postTo:(NSDictionary*)params;
@end

#pragma mark -
@implementation UmesuePostAdaptor
/**
 */
+ (NSString*) titleForMenuItem
{
	return @"Umesue";
}

+ (BOOL) enableForMenuItem
{
	return [UmesuePost isEnabled];
}

- (void) postLink:(Anchor*)anchor description:(NSString*)description
{
	if ([UmesuePost isEnabled]) {
		NSMutableDictionary* params = [[[NSMutableDictionary alloc] init] autorelease];
		[params setValue:@"LinkPost" forKey:@"type"];
		[params setValue:[anchor title] forKey:@"name"];
		[params setValue:[anchor URL] forKey:@"url"];
		[params setValue:description forKey:@"note"];
		[self postTo:params];
	}
}

- (void) postQuote:(Anchor*)anchor quote:(NSString*)quote
{
	if ([UmesuePost isEnabled]) {
		NSMutableDictionary* params = [[[NSMutableDictionary alloc] init] autorelease];
		[params setValue:@"QuotePost" forKey:@"type"];
		[params setValue:quote forKey:@"quote"];
		[params setValue:[anchor tag] forKey:@"source"];
		[self postTo:params];
	}
}

- (void) postPhoto:(Anchor*)anchor image:(NSString*)imageURL caption:(NSString*)caption
{
	if ([UmesuePost isEnabled]) {
		NSMutableDictionary* params = [[[NSMutableDictionary alloc] init] autorelease];
		[params setValue:@"PhotoPost" forKey:@"type"];
		[params setValue:imageURL forKey:@"image"];
		[params setValue:caption forKey:@"caption"];
		[params setValue:[anchor URL] forKey:@"link"];
		[self postTo:params];
	}
}

- (void) postVideo:(Anchor*)anchor embed:(NSString*)embed caption:(NSString*)caption
{
	if ([UmesuePost isEnabled]) {
		NSMutableDictionary* params = [[[NSMutableDictionary alloc] init] autorelease];
		[params setValue:@"VideoPost" forKey:@"type"];
		[params setValue:embed forKey:@"url"];
		[params setValue:caption forKey:@"caption"];
		[self postTo:params];
	}
}

/**
 * postEntry.
 *	@param パラメータ
 */
- (NSObject*) postEntry:(NSDictionary*)params
{
	TumblrReblogExtracter* extracter = [[TumblrReblogExtracter alloc] initWith:self];
	[extracter extract:[params objectForKey:@"pid"] key:[params objectForKey:@"rk"]];
	return @"";
}

/**
 * TumblrReblogExtracter の callback
 */
- (void) extract:(NSObject*)obj
{
	V(@"extract: obj=%@", SafetyDescription(obj));

	Class clazz = [obj class];
	if ([clazz isSubclassOfClass:[NSString class]]) {
		[self callbackWith:(NSString*)obj];
	}
	else if ([clazz isSubclassOfClass:[NSDictionary class]]) {
		NSDictionary* e = (NSDictionary*)obj;
		NSString* type = [e objectForKey:@"type"];

		if ([type isEqualToString:@"link"]) {
			NSMutableDictionary* params = [[[NSMutableDictionary alloc] init] autorelease];
			[params setValue:@"LinkPost" forKey:@"type"];
			[params setValue:[e objectForKey:@"post[one]"] forKey:@"name"];
			[params setValue:[e objectForKey:@"post[two]"] forKey:@"url"];
			[params setValue:[e objectForKey:@"post[three]"] forKey:@"note"];
			[self postTo:params];
		}
		else if ([type isEqualToString:@"photo"]) {
			NSMutableDictionary* params = [[[NSMutableDictionary alloc] init] autorelease];
			[params setValue:@"PhotoPost" forKey:@"type"];
			[params setValue:[e objectForKey:@"imgsrc"] forKey:@"image"];
			[params setValue:[e objectForKey:@"post[two]"] forKey:@"caption"];
			[params setValue:[e objectForKey:@"post[three]"] forKey:@"link"];
			[self postTo:params];
		}
		else if ([type isEqualToString:@"quote"]) {
			NSMutableDictionary* params = [[[NSMutableDictionary alloc] init] autorelease];
			[params setValue:@"QuotePost" forKey:@"type"];
			[params setValue:[e objectForKey:@"post[one]"] forKey:@"quote"];
			[params setValue:[e objectForKey:@"post[two]"] forKey:@"source"];
			[self postTo:params];
		}
		else if ([type isEqualToString:@"regular"]) {
			NSMutableDictionary* params = [[[NSMutableDictionary alloc] init] autorelease];
			[params setValue:@"TextPost" forKey:@"type"];
			[params setValue:[e objectForKey:@"post[one]"] forKey:@"title"];
			[params setValue:[e objectForKey:@"post[two]"] forKey:@"body"];
			[self postTo:params];
		}
		else if ([type isEqualToString:@"conversation"]) {
			[self callbackWith:[NSString stringWithFormat:@"\"%@\" post not supported yet", type]];
		}
		else if ([type isEqualToString:@"video"]) {
			NSMutableDictionary* params = [[[NSMutableDictionary alloc] init] autorelease];
			[params setValue:@"VideoPost" forKey:@"type"];
			[params setValue:[e objectForKey:@"post[one]"] forKey:@"url"];
			[params setValue:[e objectForKey:@"post[two]"] forKey:@"caption"];
			[self postTo:params];
		}
	}
}
@end

#pragma mark -
@implementation UmesuePostAdaptor (Private)
/**
 * post to del.icio.us
 */
- (void) postTo:(NSDictionary*)params
{
	@try {
		/* del.icio.us へポストするオブジェクトを生成する */
		UmesuePost* umesue = [[UmesuePost alloc] initWithCallback:callback_];

		/* リクエストパラメータを構築する */
		NSMutableDictionary* requestParams = [umesue createMinimumRequestParams];
		[requestParams addEntriesFromDictionary:params];
		V(@"requestParams: %@", [requestParams description]);

		/* del.icio.us へポストする */
		[umesue postWith:requestParams];
	}
	@catch (NSException* e) {
		[self callbackWithException:e];
	}
}
@end

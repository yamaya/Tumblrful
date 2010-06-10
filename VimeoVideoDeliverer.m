/**
 * @file VimeoVideoDeliverer.m
 * @brief VimeoVideoDeliverer implementation class
 * @author Masayuki YAMAYA
 * @date 2008-05-10
 */
#import "VimeoVideoDeliverer.h"
#import "DelivererRules.h"
#import "Log.h"
#import <WebKit/DOMHTMLEmbedElement.h>
#import <CommonCrypto/CommonDigest.h>

//#define V(format, ...)	Log(format, __VA_ARGS__)
#define V(format, ...)

/* for Vimeo API */
#define API_KEY		(@"b83e12234274c5e3c307a83aa84a8176")
#define API_SECRET	(@"c9afd3ef0")

@interface VimeoVideoDeliverer(Private)
- (NSString*)getVideoID:(NSString*)url;
- (NSString*)signatureForVimeo:(NSDictionary*)params;
- (NSString*)makeCaption:(NSXMLDocument*)document videoID:(NSString*)videoID;
- (NSString*)makeEmbedTag:(NSXMLDocument*)document videoID:(NSString*)videoID;
- (void)failedWith:(NSString*)videoID message:(NSString*)message;
- (void)failedWith:(NSString*)videoID error:(NSError*)error;
- (void)failedWith:(NSString*)videoID exception:(NSException*)exception;
@end

@implementation VimeoVideoDeliverer(Private)
/**
 * URL から videoID を得る.
 */
- (NSString*) getVideoID:(NSString*)urlAsString
{
	/* urlAsString is http://www.vimeo.com/1237052?pg=embed&sec=1237052 */
	NSURL* url = [NSURL URLWithString:urlAsString];
	if (url != nil) {
		NSString* path = [url path]; /* path is "/1237052" */
		V(@"path=%@", path);
		return [path substringFromIndex:1];
	}
	V(@"Couldn't create URL from %@", urlAsString);
	return nil;
}

/**
 * Vimeo API 用の signature を生成する.
 *	@param API パラメータの連想配列.
 *	@return signature
 */
- (NSString*) signatureForVimeo:(NSDictionary*)params
{
	NSMutableString* s = [[[NSMutableString alloc] initWithString:API_SECRET] autorelease];

	/* params はキーのalphabetソートが為されていなければならない */
	NSArray* keys = [[params allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];

	NSEnumerator* enumrator = [keys objectEnumerator];
	NSString* key;
	while ((key = [enumrator nextObject]) != nil) {
		V(@"key=%@", key);
		[s appendString:key];
		[s appendString:[params objectForKey:key]];
	}
	// c9afd3ef0api_keyb83e12234274c5e3c307a83aa84a8176methodvimeo.videos.getInfovideo_id1237052
	V(@"signature base=%@", s);	

	/* MD5 を得る */
	const char* cstr = [s UTF8String];  /* C文字列(UTF-8)を取得する */
	unsigned char md5[CC_MD5_DIGEST_LENGTH];   /* MD5の計算結果を保持する領域 */
	CC_MD5(cstr, (CC_LONG)strlen(cstr), md5); /* MD5の計算を実行する */

	NSString* sig = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
		md5[0], md5[1], md5[2], md5[3], md5[4], md5[5], md5[6], md5[7], md5[8], md5[9], md5[10], md5[11], md5[12], md5[13], md5[14], md5[15]];

	V(@"signature=%@", sig); // 640fd4ebfbbe1891c3c281fc1531bf3f
	return sig;
}

/**
 */
- (NSXMLDocument*) getVideoInfo:(NSString*)videoID
{
	NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		API_KEY, @"api_key",
		@"vimeo.videos.getInfo", @"method",
		videoID, @"video_id",
		nil];

	NSString* signature = [self signatureForVimeo:params];

	[params setValue:signature forKey:@"api_sig"];

	NSEnumerator* enumrator = [params keyEnumerator];
	NSString* key = nil;
	NSMutableString* urlAsString = [[[NSMutableString alloc] initWithString:@"http://vimeo.com/api/rest?"] autorelease];
	while ((key = [enumrator nextObject]) != nil) {
		[urlAsString appendFormat:@"%@=%@&", key, [params objectForKey:key]];
	}
	[urlAsString deleteCharactersInRange:NSMakeRange([urlAsString length] - 1, 1)];
	V(@"Vimeo API URL=%@", urlAsString);
	// http://www.vimeo.com/api/rest?api_key=b83e12234274c5e3c307a83aa84a8176&method=vimeo.videos.getInfo&video_id=1237052&api_sig=640fd4ebfbbe1891c3c281fc1531bf3f

	NSXMLDocument* document = nil;

	@try {
		/* GET via HTTP */
		NSURLRequest* request =
			[NSURLRequest requestWithURL:[NSURL URLWithString:urlAsString] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30];

		NSURLResponse* response = nil;
		NSError* error = nil;
		NSData* xmlData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
		V(@"%@", [[[NSString alloc] initWithData:xmlData encoding:NSUTF8StringEncoding] autorelease]);

		error = nil;
		document = [[NSXMLDocument alloc] initWithData:xmlData options:NSXMLDocumentTidyXML error:&error];
		if (document == nil) {
			[self failedWith:[NSString stringWithFormat:@"Couldn't get response %@", videoID] error:error];
		}
	}
	@catch (NSException* e) {
		[self failedWith:videoID exception:e];
		document = nil;
	}
	return document;
}

/**
 */
- (NSString*) makeEmbedTag:(NSXMLDocument*)document videoID:(NSString*)videoID
{
	NSString* width = @"500";
	NSString* height = @"500";

	@try {
		NSError* error = nil;
		NSArray* nodes = [document nodesForXPath:@"/rsp/video/width" error:&error];
		V(@"nodes=%@", [nodes description]);
		width = [[nodes objectAtIndex:0] objectValue];

		nodes = [document nodesForXPath:@"/rsp/video/height" error:&error];
		V(@"nodes=%@", [nodes description]);
		height = [[nodes objectAtIndex:0] objectValue];
	}
	@catch (NSException* e) {
		[self failedWith:videoID exception:e];
		return nil;
	}
	if (height == nil || width == nil) {
		[self failedWith:videoID message:@"Could not get width/height"];
		return nil;
	}

	NSMutableString* s = [[[NSMutableString alloc] init] autorelease];

	[s appendFormat:@"<object type=\"application/x-shockwave-flash\" width=\"%@\" height=\"%@\"", width, height];
	[s appendFormat:@" data=\"http://www.vimeo.com/moogaloop.swf?clip_id=%@", videoID];
	[s appendString:@"&amp;server=www.vimeo.com&amp;fullscreen=0&amp;show_title=0"];
	[s appendString:@"&amp;show_byline=0&amp;showportrait=0&amp;color=00ADEF\">"];
	[s appendString:@"<param name=\"quality\" value=\"best\" />"];
	[s appendString:@"<param name=\"allowfullscreen\" value=\"false\" />"];
	[s appendString:@"<param name=\"scale\" value=\"showAll\" />"];
	[s appendFormat:@"<param name=\"movie\" value=\"http://www.vimeo.com/moogaloop.swf?clip_id=%@", videoID];
	[s appendString:@"&amp;server=www.vimeo.com&amp;fullscreen=0&amp;"];
	[s appendString:@"show_title=0&amp;show_byline=0&amp;showportrait=0&amp;color=00ADEF\" /></object>"];

	return s;
}

- (NSString*)makeCaption:(NSXMLDocument*)document videoID:(NSString*)videoID
{
	NSError* error = nil;
	NSArray* nodes = nil;
	NSXMLElement* node = nil;
	
	nodes = [document nodesForXPath:@"rsp/video/title" error:&error];
	NSString* anchorForVideo =
		[NSString stringWithFormat:@"<a href=\"http://www.vimeo.com/%@\">%@</a>",
			 videoID, [[nodes objectAtIndex:0] objectValue]];

	nodes = [document nodesForXPath:@"rsp/video/owner" error:&error];
	node = [nodes objectAtIndex:0];
	NSString* anchorForUser =
		[NSString stringWithFormat:@"<a href=\"http://www.vimeo.com/%@\">%@</a>",
			 [[node attributeForName:@"username"] stringValue],
			 [[node attributeForName:@"fullname"] stringValue]];

	NSString* caption =
	 	[NSString stringWithFormat:@"%@ (via %@)", anchorForVideo, anchorForUser];
	V(@"caption=%@", caption);

	return caption;
}

/**
 * エラー処理
 */
- (void) failedWith:(NSString*)videoID message:(NSString*)message
{
	NSString* s = [NSString stringWithFormat:@"%@ - VideoID:%@", message, videoID];
	[self notify:[DelivererRules errorMessageWith:s]];
}

/**
 * エラー処理
 */
- (void) failedWith:(NSString*)videoID error:(NSError*)error
{
	[self failedWith:videoID message:[error description]];
}

/**
 * エラー処理
 */
- (void) failedWith:(NSString*)videoID exception:(NSException*)exception
{
	[self failedWith:videoID message:[exception description]];
}
@end

@implementation VimeoVideoDeliverer
/**
 * Deliverer のファクトリ
 */
+ (id<Deliverer>) create:(DOMHTMLDocument*)document element:(NSDictionary*)clickedElement
{
	V(@"clickedElement:%@", [clickedElement description]);

	id node = [clickedElement objectForKey:WebElementDOMNodeKey];
	if (node == nil) {
		return nil;
	}

	V(@"DOMNode:%@", [node description]);

	/* check URL's host */
	NSURL* url = [NSURL URLWithString:[[document URL] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	if ([[url host] hasSuffix:@"vimeo.com"] == NO) {
		return nil;
	}
	NSInteger no = [[[url path] substringFromIndex:1] integerValue];
	V(@"no = %d", no);
	if (no == 0) {
		return nil;
	}

	/* create object */
	VimeoVideoDeliverer* deliverer = nil;
	deliverer = [[VimeoVideoDeliverer alloc] initWithDocument:document element:clickedElement];
	if (deliverer != nil) {
		return [deliverer retain]; //need?
	}
	Log(@"Could not alloc+init %@Deliverer.", [self name]);

	return deliverer;
}

/**
 * MenuItemのタイトルを返す
 */
- (NSString*) titleForMenuItem
{
	return [NSString stringWithFormat:@"%@ - Vimeo", [VimeoVideoDeliverer name]];
}

/**
 * makeContextForVimeo.
 * 2008-07-06: embed タグを javascript で生成するようになった事により XPath でDOMが引けなくなった。打つ手なし...
 */
- (NSDictionary*) makeContextForVimeo
{
	DOMNode* clickedNode = [clickedElement_ objectForKey:WebElementDOMNodeKey];
	if (clickedNode == nil) {
		V(@"clickedNode not found: %@", clickedElement_);
		return nil;
	}

	NSString* caption = nil;
	NSString* embed = nil;
	NSString* videoID = nil;

	/* videoID をURLから得る http://www.vimeo.com/1237052?pg=embed&sec=1237052 */
	videoID = [self getVideoID:[context_ documentURL]];
	V(@"videoID=%@", videoID);

	/* Vimeo API 経由で Video 情報を XML 形式で得る */
	NSXMLDocument* xml = [self getVideoInfo:videoID];
	if (xml != nil) {
		caption = [self makeCaption:xml videoID:videoID];
		embed = [self makeEmbedTag:xml videoID:videoID];
	}

	NSMutableDictionary* context = [[[NSMutableDictionary alloc] init] autorelease];
	[context setValue:embed forKey:@"embed"];
	[context setValue:caption forKey:@"caption"];
	[context setValue:@"" forKey:@"title"]; /* title は未サポート */

	return context;
}

/**
 * メニューのアクション
 */
- (void)action:(id)sender
{
#pragma unused (sender)
	@try {
		NSDictionary * context = [self makeContextForVimeo];
		if (context != nil) {
			[super postVideo:[context objectForKey:@"embed"] title:[context objectForKey:@"title"] caption:[context objectForKey:@"caption"]];
		}
	}
	@catch (NSException * e) {
		[self failedWithException:e];
	}
}
@end

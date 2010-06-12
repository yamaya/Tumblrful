/**
 * @file VimeoVideoDeliverer.m
 * @brief VimeoVideoDeliverer implementation class
 * @author Masayuki YAMAYA
 * @date 2008-05-10
 */
#import "VimeoVideoDeliverer.h"
#import "DelivererRules.h"
#import "DebugLog.h"
#import <WebKit/DOMHTMLEmbedElement.h>
#import <CommonCrypto/CommonDigest.h>

#define TIMEOUT	(30)

// for Vimeo API
#define API_KEY		(@"b83e12234274c5e3c307a83aa84a8176")
#define API_SECRET	(@"c9afd3ef0")

@interface VimeoVideoDeliverer ()
- (NSString *)vimeoVideoIDWithURL:(NSString *)URL;
- (NSString *)vimeoSignatureWithParams:(NSDictionary *)params;
- (NSXMLDocument *)getVideoInfoXMLWithVideoID:(NSString *)videoID;
- (NSString *)captionWithXML:(NSXMLDocument *)document withVideoID:(NSString *)videoID;
- (NSString *)embedTagWithXML:(NSXMLDocument *)document withVideoID:(NSString *)videoID;
- (void)failedWithVideoID:(NSString *)videoID message:(NSString *)message;
- (void)failedWithVideoID:(NSString *)videoID error:(NSError *)error;
- (void)failedWithVideoID:(NSString *)videoID exception:(NSException *)exception;
@end

@implementation VimeoVideoDeliverer

+ (id<Deliverer>)create:(DOMHTMLDocument *)document element:(NSDictionary *)clickedElement
{
	D(@"clickedElement:%@", [clickedElement description]);

	VimeoVideoDeliverer * deliverer = nil;
	id node = [clickedElement objectForKey:WebElementDOMNodeKey];
	if (node != nil) {
		D(@"DOMNode:%@", [node description]);

		// check URL's host
		NSURL* url = [NSURL URLWithString:[[document URL] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
		if ([[url host] hasSuffix:@"vimeo.com"]) {
			NSInteger no = [[[url path] substringFromIndex:1] integerValue];
			D(@"no = %d", no);
			if (no != 0) {
				deliverer = [[VimeoVideoDeliverer alloc] initWithDocument:document element:clickedElement];
				if (deliverer == nil) {
					D(@"could not alloc+init %@Deliverer.", [self name]);
				}
			}
		}
	}
	return deliverer;
}

- (NSString *)titleForMenuItem
{
	return [NSString stringWithFormat:@"%@ - Vimeo", [VimeoVideoDeliverer name]];
}

// 2008-07-06: embed タグを javascript で生成するようになった事により XPath でDOMが引けなくなった。打つ手なし...
- (NSDictionary *)videoContents
{
	DOMNode* clickedNode = [clickedElement_ objectForKey:WebElementDOMNodeKey];
	if (clickedNode == nil) {
		D(@"clickedNode not found: %@", clickedElement_);
		return nil;
	}

	NSString * caption = nil;
	NSString * embed = nil;

	// videoID をURLから得る http://www.vimeo.com/1237052?pg=embed&sec=1237052
	NSString * videoID = [self vimeoVideoIDWithURL:[context_ documentURL]];
	D(@"videoID=%@", videoID);

	// Vimeo API 経由で Video 情報を XML 形式で得る
	NSXMLDocument * xmlDoc = [self getVideoInfoXMLWithVideoID:videoID];
	if (xmlDoc != nil) {
		caption = [self captionWithXML:xmlDoc withVideoID:videoID];
		embed = [self embedTagWithXML:xmlDoc withVideoID:videoID];
	}

	return [NSDictionary dictionaryWithObjectsAndKeys:embed, @"source", caption, @"caption", nil];
}

/**
 * URL から videoID を得る
 *	@param[in] URL	URL
 *	@return videoID
 */
- (NSString *)vimeoVideoIDWithURL:(NSString *)URL
{
	// URL is http://www.vimeo.com/1237052?pg=embed&sec=1237052
	NSURL * urlObj = [NSURL URLWithString:URL];
	if (urlObj != nil) {
		NSString * path = [urlObj path]; // path is "/1237052"
		D(@"path=%@", path);
		return [path substringFromIndex:1];
	}

	D(@"Couldn't create URL from %@", URL);
	return nil;
}

/**
 * Vimeo API 用の signature を生成する.
 *	@param API パラメータの連想配列.
 *	@return signature
 */
- (NSString *)vimeoSignatureWithParams:(NSDictionary*)params
{
	NSMutableString * secret = [[[NSMutableString alloc] initWithString:API_SECRET] autorelease];

	// params はキーのalphabetソートが為されていなければならない
	NSArray* keys = [[params allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];

	NSEnumerator * enumrator = [keys objectEnumerator];
	NSString * key;
	while ((key = [enumrator nextObject]) != nil) {
		D(@"key=%@", key);
		[secret appendString:key];
		[secret appendString:[params objectForKey:key]];
	}
	// c9afd3ef0api_keyb83e12234274c5e3c307a83aa84a8176methodvimeo.videos.getInfovideo_id1237052
	D(@"signature base=%@", secret);	

	// MD5 を得る
	const char* cstr = [secret UTF8String];  // C文字列(UTF-8)を取得する
	unsigned char md5[CC_MD5_DIGEST_LENGTH];   // MD5の計算結果を保持する領域
	CC_MD5(cstr, (CC_LONG)strlen(cstr), md5); // MD5の計算を実行する

	NSString * sig = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
		md5[0], md5[1], md5[2], md5[3], md5[4], md5[5], md5[6], md5[7], md5[8], md5[9], md5[10], md5[11], md5[12], md5[13], md5[14], md5[15]];
	D(@"signature=%@", sig); // 640fd4ebfbbe1891c3c281fc1531bf3f

	return sig;
}

- (NSXMLDocument *)getVideoInfoXMLWithVideoID:(NSString *)videoID
{
	NSMutableDictionary * params = [NSMutableDictionary dictionaryWithObjectsAndKeys:API_KEY, @"api_key", @"vimeo.videos.getInfo", @"method", videoID, @"video_id", nil];
	[params setObject:[self vimeoSignatureWithParams:params] forKey:@"api_sig"];

	NSEnumerator * enumrator = [params keyEnumerator];
	NSString * key = nil;
	NSMutableString * urlAsString = [NSMutableString stringWithString:@"http://vimeo.com/api/rest?"];
	while ((key = [enumrator nextObject]) != nil) {
		[urlAsString appendFormat:@"%@=%@&", key, [params objectForKey:key]];
	}
	[urlAsString deleteCharactersInRange:NSMakeRange([urlAsString length] - 1, 1)];
	D(@"Vimeo API URL=%@", urlAsString);
	// http://www.vimeo.com/api/rest?api_key=b83e12234274c5e3c307a83aa84a8176&method=vimeo.videos.getInfo&video_id=1237052&api_sig=640fd4ebfbbe1891c3c281fc1531bf3f

	NSXMLDocument * xmlDoc = nil;

	@try {
		// GET via HTTP
		NSURLRequest * request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlAsString] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:TIMEOUT];

		NSURLResponse * response = nil;
		NSError * error = nil;
		NSData * xmlData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
		D0([[[NSString alloc] initWithData:xmlData encoding:NSUTF8StringEncoding] autorelease]);

		error = nil;
		xmlDoc = [[NSXMLDocument alloc] initWithData:xmlData options:NSXMLDocumentTidyXML error:&error];
		if (xmlDoc == nil) {
			[self failedWithVideoID:videoID error:error];
		}
	}
	@catch (NSException * e) {
		D0([e description]);
		[self failedWithVideoID:videoID exception:e];
		xmlDoc = nil;
	}
	return xmlDoc;
}

- (NSString *)embedTagWithXML:(NSXMLDocument*)xmlDoc withVideoID:(NSString *)videoID
{
	NSString * width = @"500";
	NSString * height = @"500";

	@try {
		NSError * error = nil;
		NSArray * nodes = [xmlDoc nodesForXPath:@"/rsp/video/width" error:&error];
		D(@"nodes=%@", [nodes description]);
		width = [[nodes objectAtIndex:0] objectValue];

		nodes = [xmlDoc nodesForXPath:@"/rsp/video/height" error:&error];
		D(@"nodes=%@", [nodes description]);
		height = [[nodes objectAtIndex:0] objectValue];
	}
	@catch (NSException * e) {
		D0([e description]);
		[self failedWithVideoID:videoID exception:e];
		return nil;
	}
	if (height == nil || width == nil) {
		[self failedWithVideoID:videoID message:@"Could not get width and height"];
		return nil;
	}

	NSMutableString * embed = [NSMutableString string];
	[embed appendFormat:@"<object type=\"application/x-shockwave-flash\" width=\"%@\" height=\"%@\"", width, height];
	[embed appendFormat:@" data=\"http://www.vimeo.com/moogaloop.swf?clip_id=%@", videoID];
	[embed appendString:@"&amp;server=www.vimeo.com&amp;fullscreen=0&amp;show_title=0"];
	[embed appendString:@"&amp;show_byline=0&amp;showportrait=0&amp;color=00ADEF\">"];
	[embed appendString:@"<param name=\"quality\" value=\"best\" />"];
	[embed appendString:@"<param name=\"allowfullscreen\" value=\"false\" />"];
	[embed appendString:@"<param name=\"scale\" value=\"showAll\" />"];
	[embed appendFormat:@"<param name=\"movie\" value=\"http://www.vimeo.com/moogaloop.swf?clip_id=%@", videoID];
	[embed appendString:@"&amp;server=www.vimeo.com&amp;fullscreen=0&amp;"];
	[embed appendString:@"show_title=0&amp;show_byline=0&amp;showportrait=0&amp;color=00ADEF\" /></object>"];
	return embed;
}

- (NSString *)captionWithXML:(NSXMLDocument *)xmlDoc withVideoID:(NSString *)videoID
{
	NSError * error = nil;
	NSArray * nodes = nil;
	NSXMLElement * node = nil;

	nodes = [xmlDoc nodesForXPath:@"rsp/video/title" error:&error];
	NSString * videoAnchor = [NSString stringWithFormat:@"<a href=\"http://www.vimeo.com/%@\">%@</a>", videoID, [[nodes objectAtIndex:0] objectValue]];

	nodes = [xmlDoc nodesForXPath:@"rsp/video/owner" error:&error];
	node = [nodes objectAtIndex:0];
	NSString * userAnchor = [NSString stringWithFormat:@"<a href=\"http://www.vimeo.com/%@\">%@</a>", [[node attributeForName:@"username"] stringValue], [[node attributeForName:@"fullname"] stringValue]];

	NSString * caption = [NSString stringWithFormat:@"%@ (via %@)", videoAnchor, userAnchor];
	D(@"caption=%@", caption);

	return caption;
}

- (void)failedWithVideoID:(NSString *)videoID message:(NSString *)message
{
	NSString * s = [NSString stringWithFormat:@"%@ - VideoID:%@", message, videoID];
	[self notify:[DelivererRules errorMessageWith:s]];
}

- (void)failedWithVideoID:(NSString *)videoID error:(NSError*)error
{
	[self failedWithVideoID:videoID message:[error description]];
}

- (void)failedWithVideoID:(NSString *)videoID exception:(NSException*)exception
{
	[self failedWithVideoID:videoID message:[exception description]];
}
@end

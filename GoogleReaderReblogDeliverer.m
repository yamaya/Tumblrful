/**
 * @file GoogleReaderReblogDeliverer.m
 * @brief GoogleReaderReblogDeliverer implementation
 * @author Masayuki YAMAYA
 * @date 2008-11-16
 */
// /System/Library/Frameworks/WebKit.framework/Headers/DOMHTMLDocument.h
#import "GoogleReaderReblogDeliverer.h"
#import "GoogleReaderDelivererContext.h"
#import "Log.h"
#import <WebKit/WebKit.h>

//#define V(format, ...)	Log(format, __VA_ARGS__)
#define V(format, ...)

//TODO この２つも LDRReblogDeliverer から getter で取得できるようにする
static NSString* TUMBLR_DOMAIN = @".tumblr.com";
static NSString* TUMBLR_DATA_URI = @"htpp://data.tumblr.com/";

#pragma mark -
@implementation GoogleReaderReblogDeliverer
/**
 * create.
 *	@param document DOMHTMLDocument オブジェクト
 *	@param clickedElement クリックしたDOM要素の情報
 *	@return Deliverer オブジェクト
 */
+ (id<Deliverer>) create:(DOMHTMLDocument*)document element:(NSDictionary*)clickedElement
{
	if (![GoogleReaderDelivererContext match:document target:clickedElement]) {
		return nil;
	}

	/* あーあ、しょうがないので自力で GoogleReaderDelivererContext を生成するよ */
	GoogleReaderDelivererContext* context =
		[[GoogleReaderDelivererContext alloc] initWithDocument:document
																					 target:clickedElement];
	if (context == nil) {
		return nil;
	}
	[context autorelease];

	NSURL* url = [NSURL URLWithString:[context documentURL]];
	if (url == nil) {
		return nil;
	}
	V(@"URL:", [url absoluteString]);

	NSRange range;
	DOMNode* node = [clickedElement objectForKey:WebElementImageURLKey];
	if (node != nil && [[node className] isEqualToString:@"DOMHTMLImageElement"]) {
		DOMHTMLImageElement* img = (DOMHTMLImageElement*)node;
		range = [[img src] rangeOfString:TUMBLR_DATA_URI];
		if (!(range.location == 0 && range.length >= [TUMBLR_DATA_URI length])) {
			V(@"GoogleReaderReblogDeliverer: type is Photo but On %@", TUMBLR_DATA_URI);
			return nil;
		}
	}
	else {
		range = [[url host] rangeOfString:TUMBLR_DOMAIN];
		if (!(range.location > 0 && range.length == [TUMBLR_DOMAIN length])) {
			V(@"GoogleReaderReblogDeliverer: Not in %@", TUMBLR_DOMAIN);
			return nil;
		}
	}

	GoogleReaderReblogDeliverer* deliverer = nil;

	NSString* postID = [[context documentURL] lastPathComponent];
	if (postID == nil) {
		V(@"Could not get PostID. element:%@", [clickedElement description]);
		return nil;
	}

	/* Google Reader ではこの時点で ReblogKey は得られないので nil を指定する */
	deliverer =
		[[GoogleReaderReblogDeliverer alloc] initWithDocument:document
																					target:clickedElement
																					postID:postID
																			 reblogKey:nil];
	if (deliverer != nil) {
		[deliverer retain];	//TODO: need?
	}
	else {
		Log(@"Could not alloc+init %@.", [GoogleReaderReblogDeliverer className]);
	}
	return deliverer;
}
@end

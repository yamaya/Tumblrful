/**
 * @file GoogleReaderReblogDeliverer.m
 * @brief GoogleReaderReblogDeliverer implementation
 * @author Masayuki YAMAYA
 * @date 2008-11-16
 */
// /System/Library/Frameworks/WebKit.framework/Headers/DOMHTMLDocument.h
#import "GoogleReaderReblogDeliverer.h"
#import "GoogleReaderDelivererContext.h"
#import "DebugLog.h"
#import <WebKit/WebKit.h>

#pragma mark -
@implementation GoogleReaderReblogDeliverer

+ (id<Deliverer>)create:(DOMHTMLDocument *)document element:(NSDictionary *)clickedElement
{
	// Tumblr ポストかどうかのチェック
	if (![GoogleReaderDelivererContext match:document target:clickedElement]) return nil;

	// GoogleReaderDelivererContext を生成する
	GoogleReaderDelivererContext * context = [[[GoogleReaderDelivererContext alloc] initWithDocument:document target:clickedElement] autorelease];

	NSURL * url = [NSURL URLWithString:context.URLOfDocument];
	if (url == nil) return nil;

	D(@"URL:%@", [url absoluteString]);

	NSRange range;
	DOMNode * node = [clickedElement objectForKey:WebElementImageURLKey];
	if (node != nil && [[node className] isEqualToString:@"DOMHTMLImageElement"]) {
		DOMHTMLImageElement* img = (DOMHTMLImageElement*)node;
		range = [[img src] rangeOfString:[self dataSiteURL]];
		if (!(range.location == 0 && range.length >= [[self dataSiteURL] length])) {
			D(@"GoogleReaderReblogDeliverer: type is Photo but On %@", [self dataSiteURL]);
			return nil;
		}
	}
	else {
		range = [[url host] rangeOfString:[self sitePostfix]];
		if (!(range.location > 0 && range.length == [[self sitePostfix] length])) {
			D(@"GoogleReaderReblogDeliverer: Not in %@", [self sitePostfix]);
			return nil;
		}
	}

	NSString * postID = [context.URLOfDocument lastPathComponent];
	if (postID == nil) {
		D(@"Could not get PostID. element:%@", [clickedElement description]);
		return nil;
	}

	// Google Reader ではこの時点で ReblogKey は得られないので未指定で
	GoogleReaderReblogDeliverer * deliverer = [[GoogleReaderReblogDeliverer alloc] initWithContext:context postID:postID];
	if (deliverer == nil) {
		D(@"Could not alloc+init %@.", [GoogleReaderReblogDeliverer className]);
	}

	return deliverer;
}
@end

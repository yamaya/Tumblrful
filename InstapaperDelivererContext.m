/**
 * @file InstapaperDelivererContext.m
 */
#import "InstapaperDelivererContext.h"
#import "NSString+Tumblrful.h"
#import "DebugLog.h"

static NSString * INSTAPAPER_HOSTNAME = @"www.instapaper.com";
static NSString * INSTAPAPER_PATH = @"/text";
static NSString * INSTAPAPER_PATH2 = @"/go";

@interface InstapaperDelivererContext ()
+ (BOOL)siteMatchWithURL:(NSString *)URL;
@end

@implementation InstapaperDelivererContext
+ (BOOL)match:(DOMHTMLDocument *)document target:(NSDictionary *)targetElement
{
#pragma unused (targetElement)
	return [self siteMatchWithURL:[document URL]];
}

+ (BOOL)siteMatchWithURL:(NSString *)URL
{
	NSURL * u = [NSURL URLWithString:URL];
	return u != nil &&
			[[u host] isEqualToString:INSTAPAPER_HOSTNAME] &&
			([[u path] hasPrefix:INSTAPAPER_PATH] || [[u path] hasPrefix:INSTAPAPER_PATH2]);
}

- (id)initWithDocument:(DOMHTMLDocument *)document target:(NSDictionary *)targetElement
{
	if ((self = [super initWithDocument:document target:targetElement]) != nil) {
	}
	return self;
}

- (NSString *)documentURL
{
	if (URL_ == nil) {
		// Instapaperの "Text"ページでは URLパラメーターにオリジナルサイトのURLが埋め込まれているのでそれを取り出す
		NSURL * url = [NSURL URLWithString:[self.document URL]];
		D(@"host=%@ path=%2 query=%2", [url host], [url path], [url query]);
		NSString * query = [url query];
		NSDictionary * queries = [query dictionaryWithKVPConnector:@"=" withSeparator:@"&"];;
		for (NSString * key in queries) {
			if ([key isEqualToString:@"u"]) {
				URL_ = [[queries objectForKey:@"u"] stringByURLDecoding:NSUTF8StringEncoding];
				D(@"normalized URL=%@", URL_);
				break;
			}
		}
		// なんだよ、URLパラメータにしたりしなかったり、わけわからん
		if (URL_ == nil) {
			static NSString * const kExpression = @"//div[@class='bar top']/a/@href";
			DOMXPathResult * result = [self evaluateToDocument:kExpression contextNode:self.document type:DOM_STRING_TYPE inResult:nil];
			D(@"result=%@", result);
			URL_ = result.stringValue;
		}
		if (URL_ == nil) {
			URL_ = self.documentURL;
		}
	}
	D(@"URL_=%@", URL_);
	return URL_;
}


- (NSString *)menuTitle
{
	return @" - Instapaper";
}
@end

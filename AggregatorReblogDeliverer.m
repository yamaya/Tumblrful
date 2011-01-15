/**
 * @file AggregatorDeliverer.m
 * @brief AggregatorDeliverer implementation
 * @author Masayuki YAMAYA
 * @date 2008-03-03
 */
// /System/Library/Frameworks/WebKit.framework/Headers/DOMHTMLDocument.h
#import "AggregatorReblogDeliverer.h"
#import "TumblrfulConstants.h"
#import "NSString+Tumblrful.h"
#import "DebugLog.h"
#import <WebKit/WebKit.h>
#import <objc/objc-runtime.h>

static NSString * TUMBLR_DOMAIN = @".tumblr.com";
static NSString * TUMBLR_DATA_URI = @"htpp://data.tumblr.com/";

@implementation AggregatorReblogDeliverer

+ (NSString *)sitePostfix
{
	return TUMBLR_DOMAIN;
}

+ (NSString *)dataSiteURL
{
	return TUMBLR_DATA_URI;
}

- (void)dealloc
{
	[data_ release], data_ = nil;

	[super dealloc];
}

- (void)action:(id)sender
{
#pragma unused (sender)
	@try {
		// get PostID from URL
		NSString * postID = nil;
		NSURL * u = [NSURL URLWithString:context_.documentURL];
		NSScanner * scanner = [NSScanner scannerWithString:[u path]];
		[scanner scanUpToString:@"post/" intoString:nil];
		[scanner scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:&postID];
		[scanner scanCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:&postID];
		D(@"postID=%@", postID);
		if (postID == nil || [postID longLongValue] == 0) {
			[NSException raise:TUMBLRFUL_EXCEPTION_NAME format:@"Could not PostID in %@", context_.documentURL];
		}
		self.postID = postID;

		// make Tumblr read API URL
		NSString * endpoint = [NSString stringWithFormat:@"%@://%@/api/read?id=%@", [u scheme], [u host], postID];
		D(@"API endpoint=%@", endpoint);
		NSURLRequest * request = [NSURLRequest requestWithURL:[NSURL URLWithString:endpoint]];

		NSURLConnection * connection;
		connection = [NSURLConnection connectionWithRequest:request delegate:self];	// autoreleased
	}
	@catch (NSException * e) {
		D0([e description]);
		[self failedWithException:e];
	}
}

#pragma mark -
#pragma mark Delegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
#pragma unused (connection)
	NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *)response;

	NSInteger const httpStatus = [httpResponse statusCode];
	if (httpStatus != 200 && httpStatus != 201) {
		D(@"statusCode:%d", httpStatus);
		D(@"ResponseHeader:%@", [[httpResponse allHeaderFields] description]);
	}

	data_ = [[NSMutableData data] retain];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
#pragma unused (connection)
	[data_ appendData:data]; // append data to receive buffer
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
#pragma unused (connection)
	// parse read API XML
	NSError * error = nil;
	NSXMLDocument * xmlDoc = [[[NSXMLDocument alloc] initWithData:data_ options:NSXMLDocumentTidyXML error:&error] autorelease];
	error = nil;
	NSXMLElement * post = [[xmlDoc nodesForXPath:@"/tumblr/posts/post" error:&error] lastObject];
	if (error != nil) {
		[NSException raise:TUMBLRFUL_EXCEPTION_NAME format:@"Unrecognize Tumblr read XML. %@", [error description]];
	}
	NSXMLNode * attribute = [post attributeForName:@"reblog-key"];
	D(@"%@ - %@", [attribute description], [attribute stringValue]);

	// set properties
	self.reblogKey = [attribute stringValue];
	D(@"pid=%@, rk=%@", self.postID, self.reblogKey);

	// call base class's method
	[super action:nil];

	[self autorelease];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
#pragma unused (connection)
	D0([error description]);

	[self failedWithError:error];

	[self autorelease];
}

@end

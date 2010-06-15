/**
 * @file PostAdaptor.m
 * @brief PostAdaptor class implementation.
 * @author Masayuki YAMAYA
 * @date 2008-03-07
 */
#import "PostAdaptor.h"
#import "DebugLog.h"

@implementation PostAdaptor

@synthesize callback = callback_;
@synthesize privated = privated_;
@synthesize queuingEnabled = queuingEnabled_;
@synthesize extractEnabled = extractEnabled_;
@synthesize options = options_;

+ (NSString *)titleForMenuItem
{
	return nil;
}

+ (BOOL)enableForMenuItem
{
	return YES;
}

- (id)initWithCallback:(id<PostCallback>)callback
{
	return [self initWithCallback:callback private:NO];
}

- (id)initWithCallback:(id<PostCallback>)callback private:(BOOL)private
{
	if ((self = [super init]) != nil) {
		callback_ = [callback retain];
		privated_ = private;
		queuingEnabled_ = NO;
		extractEnabled_ = YES;
	}
	return self;
}

- (void)dealloc
{
	[callback_ release], callback_ = nil;
	[options_ release], options_ = nil;

	[super dealloc];
}

- (void)callbackWith:(NSString *)response
{
	if (callback_ != nil) [callback_ successed:response];
}

- (void)callbackWithError:(NSError *)error
{
	if (callback_ != nil) [callback_ failedWithError:error];
}

- (void)callbackWithException:(NSException *)exception
{
	if (callback_ != nil) [callback_ failedWithException:exception];
}

- (void)postLink:(Anchor *)anchor description:(NSString *)description
{
#pragma unused (anchor, description)
	[self doesNotRecognizeSelector:_cmd];
}

- (void)postQuote:(NSString *)quote source:(NSString *)source
{
#pragma unused (quote, source)
	[self doesNotRecognizeSelector:_cmd];
}

- (void)postPhoto:(NSString *)source caption:(NSString *)caption throughURL:(NSString *)throughURL
{
#pragma unused (source, caption, throughURL)
	[self doesNotRecognizeSelector:_cmd];
}

- (void)postVideo:(NSString *)embed caption:(NSString*)caption
{
#pragma unused (embed, title, caption)
	[self doesNotRecognizeSelector:_cmd];
}

- (void)postEntry:(NSDictionary *)params
{
#pragma unused (params)
	[self doesNotRecognizeSelector:_cmd];
}

static SEL selectorOf(PostType postType);

SEL selectorOf(PostType postType)
{
	D0([NSString stringWithPostType:postType]);

	switch (postType) {
	case RegularPostType:		break;
	case LinkPostType:			return @selector(postLink:description:);
	case QuotePostType:			return @selector(postQuote:source:);
	case PhotoPostType:			return @selector(postPhoto:caption:throughURL:);
	case ConversationPostType:	break;
	case VideoPostType:			return @selector(postVideo:caption:);
	case AudioPostType:			break;
	case ReblogPostType:		return @selector(postEntry:);
	case UndefinedPostType:		break;
	}
	return nil;
}

- (NSInvocation *)invocationWithPostType:(PostType)postType
{
	NSInvocation * invocation = nil;

	SEL selector = selectorOf(postType);
	if (selector != nil) {
		NSMethodSignature * signature = [self.class instanceMethodSignatureForSelector:selector];
		invocation = [NSInvocation invocationWithMethodSignature:signature];
		[invocation setTarget:self];
		[invocation setSelector:selector];
	}
	else {
		D(@"unsupported invocation's post-type=%@", [NSString stringWithPostType:postType]);
	}

	return invocation;
}
@end

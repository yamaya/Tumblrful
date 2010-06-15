/**
 * @file PostType.m
 * @brief PostType type implementation
 * @author Masayuki YAMAYA
 * @date 2010-06-01
 */
#import "PostType.h"

@implementation NSString (TumblrfulPostTypeAddition)
+ (NSString *)stringWithPostType:(PostType)postType
{
	switch (postType) {
	case RegularPostType:		return @"Regular";
	case LinkPostType:			return @"Link";
	case QuotePostType:			return @"Quote";
	case PhotoPostType:			return @"Photo";
	case ConversationPostType:	return @"Conversation";
	case VideoPostType:			return @"Video";
	case AudioPostType:			return @"Audio";
	case ReblogPostType:		return @"Reblog";
	case UndefinedPostType:		break;
	}
	return @"Undefined";
}

- (PostType)postType
{
	NSString * type = [self lowercaseString];
	if ([type isEqualToString:@"link"])					return LinkPostType;
	else if ([type isEqualToString:@"photo"])			return PhotoPostType;
	else if ([type isEqualToString:@"quote"])			return QuotePostType;
	else if ([type isEqualToString:@"regular"])			return RegularPostType;
	else if ([type isEqualToString:@"conversation"])	return ConversationPostType;
	else if ([type isEqualToString:@"video"])			return VideoPostType;
	else if ([type isEqualToString:@"audio"])			return AudioPostType;

	return UndefinedPostType;
}
@end

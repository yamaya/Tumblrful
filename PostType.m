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
	case UndefinedPostType:		break;
	}
	return @"Undefined";
}
@end

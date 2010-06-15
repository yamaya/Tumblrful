#import "GrowlSupport.h"
#import "DebugLog.h"

static NSString* NOTIFY_NAME = @"NotifyPostToTumblr";

@implementation GrowlSupport

/// notify TODO: deprecated
+ (void) notify:(NSString*)title description:(NSString*)description
{
	[GrowlSupport sharedInstance];

	[GrowlApplicationBridge notifyWithTitle:title
								description:description
						   notificationName:NOTIFY_NAME
								   iconData:nil
								   priority:0
								   isSticky:NO
							   clickContext:nil];
}

/// notify
+ (void)notifyWithTitle:(NSString *)title description:(NSString *)description
{
	[GrowlSupport sharedInstance];

	[GrowlApplicationBridge notifyWithTitle:title
								description:description
						   notificationName:NOTIFY_NAME
								   iconData:nil
								   priority:0
								   isSticky:NO
							   clickContext:nil];
}

+ (GrowlSupport *)sharedInstance
{
	static GrowlSupport * instance = nil;

	if (instance == nil) {
		instance = [[GrowlSupport alloc] init];
	}
	return instance;
}

- (id)init
{
	if ((self = [super init]) != nil) {
		[GrowlApplicationBridge setGrowlDelegate:self];
	}
	return self;
}

- (NSDictionary *)registrationDictionaryForGrowl
{
	NSArray * desc = [NSArray arrayWithObject:NOTIFY_NAME];
	return [NSDictionary dictionaryWithObjectsAndKeys:[self applicationNameForGrowl], GROWL_APP_NAME, desc, GROWL_NOTIFICATIONS_ALL, desc, GROWL_NOTIFICATIONS_DEFAULT, nil];
}

- (NSString *)applicationNameForGrowl
{
	return @"Tumblrful";
}
@end

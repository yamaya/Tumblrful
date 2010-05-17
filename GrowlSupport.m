#import "GrowlSupport.h"
#import "Log.h"

@implementation GrowlSupport

static NSString* NOTIFY_NAME = @"NotifyPostToTumblr";

#define Safety(s) (s != nil ? s : @"(nil)")

/// notify
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
#if 0
	Log(@"Growl.notify title: %@ description: %@", Safety(title), Safety(description));
#endif
}

/// sharedInstance
+ (GrowlSupport*) sharedInstance
{
	static GrowlSupport* instance = nil;

	if (instance == nil) {
		instance = [[GrowlSupport alloc] init];
	}
	return instance;
}

/// init
- (id) init
{
	if (self = [super init]) {
		[GrowlApplicationBridge setGrowlDelegate:self];
		[self registrationDictionaryForGrowl];
	}
	return self;
}

/// registrationDictionaryForGrowl
- (NSDictionary*) registrationDictionaryForGrowl
{
	NSArray* registration = [NSArray arrayWithObject:NOTIFY_NAME];
	return [NSDictionary dictionaryWithObjectsAndKeys:
		[self applicationNameForGrowl], GROWL_APP_NAME,
		registration, GROWL_NOTIFICATIONS_ALL,
		registration, GROWL_NOTIFICATIONS_DEFAULT,
		nil];
}

/// applicationNameForGrowl
- (NSString*) applicationNameForGrowl
{
	return @"Tumblrful";
}
@end

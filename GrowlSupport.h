#import <Cocoa/Cocoa.h>
#import <Growl/Growl.h>

@interface GrowlSupport : NSObject <GrowlApplicationBridgeDelegate>
+ (GrowlSupport*) sharedInstance;
+ (void) notify:(NSString*)title description:(NSString*)description;
@end

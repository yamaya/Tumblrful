/**
 * @file GrowlSupport.h
 */
#import <Cocoa/Cocoa.h>
#import <Growl/Growl.h>

@interface GrowlSupport : NSObject <GrowlApplicationBridgeDelegate>

+ (GrowlSupport *)sharedInstance;

+ (void)notifyWithTitle:(NSString *)title description:(NSString *)description;

@end

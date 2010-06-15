/**
 * @file GrowlSupport.h
 */
#import <Cocoa/Cocoa.h>
#import <Growl/Growl.h>

@interface GrowlSupport : NSObject <GrowlApplicationBridgeDelegate>

+ (GrowlSupport *)sharedInstance;

//TODO deprecated
+ (void)notify:(NSString *)title description:(NSString *)description;

+ (void)notifyWithTitle:(NSString *)title description:(NSString *)description;

@end

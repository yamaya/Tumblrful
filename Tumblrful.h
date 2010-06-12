/**
 * @file Tumblrful.h
 * @brief Tumblrful class declaration
 * @author Masayuki YAMAYA
 * @date  2008-03-02
 */
#import <Cocoa/Cocoa.h>

@interface Tumblrful : NSObject
/**
 * 'sharedInstance' class method
 *	@return the single static instance of the plugin object
 */
+ (Tumblrful*) sharedInstance;
@end

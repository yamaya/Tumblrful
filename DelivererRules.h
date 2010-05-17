/**
 * @file DelivererRules.h
 * @brief DelivererRules declaration
 * @author Masayuki YAMAYA
 * @date 2008-03-03
 *
 * Deliverer に適用する規定の集合
 */
#import <WebKit/WebKit.h>

@interface DelivererRules : NSObject
+ (NSString*) menuItemTitleWith:(NSString*)suffix;
+ (NSString*) errorMessageWith:(NSString*)message;
+ (NSString*) anchorTag:(DOMHTMLDocument*)document;
+ (NSString*) anchorTagWithName:(NSString*)url name:(NSString*)name;
@end

/**
 * @file NSDataBase64.h
 * @brief NSData Base64 Category
 * @author Masayuki YAMAYA
 * @date 2008-04-19
 */
#import <Foundation/NSData.h>

@interface NSData (Base64Encode)
- (NSString*) encodeBase64;
- (NSString*) encodeBase64WithNL:(BOOL)withNL;
@end

/**
 * @file PostCallback.h
 * @brief PostCallback declaration.
 * @author Masayuki YAMAYA
 * @date 2008-03-07
 */
#import <Foundation/Foundation.h>

@protocol PostCallback <NSObject>

- (void)successed:(NSString *)response;

- (void)failedWithError:(NSError *)error;

- (void)failedWithException:(NSException *)exception;

@end

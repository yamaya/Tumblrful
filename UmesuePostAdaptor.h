/**
 * @file UmesuePostAdaptor.h
 * @brief UmesuePostAdaptor class declaration
 * @author Masayuki YAMAYA
 * @date 2008-04-19
 *
 * Deliverer と UmesuePost をつなぐ
 */
#import "PostAdaptor.h"
#import "TumblrReblogExtractor.h"

@interface UmesuePostAdaptor : PostAdaptor<TumblrReblogExtractorDelegate>
@end

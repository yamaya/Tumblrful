/**
 * @file Anchor.h
 * @brief Anchor declaration.
 * @author Masayuki YAMAYA
 * @date 2008-03-07
 */
#import <Foundation/Foundation.h>

/**
 * Anchor class
 */
@interface Anchor : NSObject
{
	NSString * url_;
	NSString * title_;
}

/// URL
@property (nonatomic, retain) NSString * URL;

/// title
@property (nonatomic, retain) NSString * title;

/// html tag
@property (nonatomic, readonly) NSString * html;

/**
 * initialize Anchor object.
 *	@param[in] url	URL string
 *	@param[in] title	title string
 *	@return initialized Anchor object
 */
- (id)initWithURL:(NSString *)url title:(NSString *)title;

/**
 * initialize Anchor object.
 *	@param[in] html	TAB separated string for URL and title
 *	@return initialized Anchor object
 */
- (id)initWithHTML:(NSString *)html;

/**
 * create Anchor object.
 *	@param[in] url	URL string
 *	@param[in] title	title string
 *	@return Anchor object
 */
+ (Anchor *)anchorWithURL:(NSString *)url title:(NSString *)title;

/**
 * create Anchor object.
 *	@param[in] html	HTML anchor tag
 *	@return Anchor object
 */
+ (Anchor *)anchorWithHTML:(NSString *)html;

/**
 * create HTML anchor tag string
 *	@param[in] url	URL string
 *	@param[in] title	title string
 *	@return HTML anchor tag
 */
+ (NSString *)htmlWithURL:(NSString *)URL title:(NSString *)title;
@end

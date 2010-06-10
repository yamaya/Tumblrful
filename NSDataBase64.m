/**
 * @file NSDataBase64.m
 * @brief NSData implementation
 * @author Masayuki YAMAYA
 * @date 2008-04-19
 */
#import "NSDataBase64.h"
#import "Log.h"
#include <openssl/bio.h>
#include <openssl/evp.h>

//#define V(format, ...)	Log(format, __VA_ARGS__)
#define V(format, ...)

@implementation NSData (Base64Encode)
/**
 * encodeBase64.
 *	@return エンコード済みの文字列
 */
- (NSString*) encodeBase64
{
	return [self encodeBase64WithNL:YES];
}

/**
 * encodeBase64WithNL.
 *	@param withNL YESで区切り文字のNL(0x0a)を付加する
 *	@return エンコード済みの文字列
 */
- (NSString*) encodeBase64WithNL:(BOOL)withNL
{
	BIO* filter = BIO_new(BIO_f_base64());
	if (withNL == NO) {
		BIO_set_flags(filter, BIO_FLAGS_BASE64_NO_NL);
	}
	BIO* memio = BIO_push(filter, BIO_new(BIO_s_mem()));
	BIO_write(memio, [self bytes], (int)[self length]);
	(void)BIO_flush(memio);

	char* bytes = NULL;
	size_t length = BIO_get_mem_data(memio, &bytes);

#ifdef DUMP_DEBUG
	for (size_t i = 0; i < length; ++i) {
		V(@"bytes[%d]={%c:%x}", i, bytes[i], bytes[i]);
	}
#endif

	NSString* result = [[NSString alloc] initWithBytes:bytes length:length encoding:NSASCIIStringEncoding];

	BIO_free_all(memio);

	return result;
}
@end

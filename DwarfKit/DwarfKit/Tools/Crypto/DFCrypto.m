/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFCrypto.h"
#import <CommonCrypto/CommonCrypto.h>

static inline
NSString *
_dwarf_hash_to_string(unsigned char *hash, unsigned int length) {
    char utf8[2 * length + 1];
    char *temp = utf8;
    for (int i = 0; i < length; i++) {
        snprintf(temp, 3, "%02x", hash[i]);
        temp += 2;
    }
    return [NSString stringWithUTF8String:utf8];
}

NSString *
dwarf_md5(const char *data, uint32_t length) {
    unsigned char hash[CC_MD5_DIGEST_LENGTH];
    CC_MD5(data, (CC_LONG)length, hash);
    return _dwarf_hash_to_string(hash, CC_MD5_DIGEST_LENGTH);
}

NSString *
dwarf_sha1(const char *data, uint32_t length) {
    unsigned char hash[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(data, (CC_LONG)length, hash);
    return _dwarf_hash_to_string(hash, CC_SHA1_DIGEST_LENGTH);
}

NSString *
dwarf_sha224(const char *data, uint32_t length) {
    unsigned char hash[CC_SHA224_DIGEST_LENGTH];
    CC_SHA224(data, (CC_LONG)length, hash);
    return _dwarf_hash_to_string(hash, CC_SHA224_DIGEST_LENGTH);
}

NSString *
dwarf_sha256(const char *data, uint32_t length) {
    unsigned char hash[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(data, (CC_LONG)length, hash);
    return _dwarf_hash_to_string(hash, CC_SHA256_DIGEST_LENGTH);
}

NSString *
dwarf_sha384(const char *data, uint32_t length) {
    unsigned char hash[CC_SHA384_DIGEST_LENGTH];
    CC_SHA384(data, (CC_LONG)length, hash);
    return _dwarf_hash_to_string(hash, CC_SHA384_DIGEST_LENGTH);
}

NSString *
dwarf_sha512(const char *data, uint32_t length) {
    unsigned char hash[CC_SHA512_DIGEST_LENGTH];
    CC_SHA512(data, (CC_LONG)length, hash);
    return _dwarf_hash_to_string(hash, CC_SHA512_DIGEST_LENGTH);
}
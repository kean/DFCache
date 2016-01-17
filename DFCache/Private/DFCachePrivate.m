// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import "DFCachePrivate.h"
#import <CommonCrypto/CommonCrypto.h>

NSString *
_dwarf_cache_to_string(unsigned char *hash, unsigned int length) {
    char utf8[2 * length + 1];
    char *temp = utf8;
    for (int i = 0; i < length; i++) {
        snprintf(temp, 3, "%02x", hash[i]);
        temp += 2;
    }
    return [NSString stringWithUTF8String:utf8];
}

NSString *
_dwarf_cache_sha1(const char *data, uint32_t length) {
    unsigned char hash[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(data, (CC_LONG)length, hash);
    return _dwarf_cache_to_string(hash, CC_SHA1_DIGEST_LENGTH);
}

NSString *
_dwarf_bytes_to_str(unsigned long long bytes) {
    return [NSByteCountFormatter stringFromByteCount:bytes countStyle:NSByteCountFormatterCountStyleBinary];
}

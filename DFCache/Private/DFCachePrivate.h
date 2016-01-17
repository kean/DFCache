// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import <Foundation/Foundation.h>

#pragma mark - Functions -

static inline void
_dwarf_cache_callback(void (^block)(id), id object) {
    if (block != nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            block(object);
        });
    }
}

/*! Produces 160-bit hash value using SHA-1 algorithm.
 @return String containing 160-bit hash value expressed as a 40 digit hexadecimal number.
 */
extern NSString *
_dwarf_cache_sha1(const char *data, uint32_t length);

/*! Returns user-friendly string with bytes.
 */
extern NSString *
_dwarf_bytes_to_str(unsigned long long bytes);

#pragma mark - Types -

typedef unsigned long long _dwarf_cache_bytes;

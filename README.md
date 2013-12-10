About DwarfKit
=========
DwarfKit is a set of highly reusable Objective-C (iOS/Mac OS X) classes and categories.
License
-------
DwarfKit is available under the MIT license.
DFImageFetchManager
-------------------
Image fetching with extreme performance. 

Key features:
 - Performance and scalability. Built entirely on top of GCD. `DFImageFetchManager` is able to maintain thousands of image requests/request cancellations per second. Even on older devices.
 - JPEG images are decompressed via `libjpeg-turbo`.
 - Resources with the same URL are never downloaded twice.

DFCache
-------
 Efficient memory and disk key-value storage.
 
 Key features:
 - General purpose. Store any Objective-C objects. Built-in support for caching objects implementing `NSCoding` protocol, JSON and images (`UIImage`).
 - Metadata. Add custom metadata for cached objects. Metadata is implemented on top of UNIX extended file attributes.
 - LRU cleanup.
 - Performance. Fantastic image decoding performance of `libjpeg-turbo` (implemented as a category `DFCache+UIImage`).
 - Thread safety.

DFStorage
---------
General purpose key-value file storage.

NSURL+DFExtendedFileAttributes
------------------------------
Objective-c wrapper of UNIX extended file attributes.
```objective-c
- (int)setExtendedAttributeValue:(id<NSCoding>)value forKey:(NSString *)key;
- (id)extendedAttributeValueForKey:(NSString *)key error:(int *)error;
- (int)removeExtendedAttributeForKey:(NSString *)key;
- (NSArray *)extendedAttributesList:(int *)error;

- (int)setExtendedAttributeData:(NSData *)data forKey:(NSString *)key options:(int)options;
- (NSData *)extendedAttributeDataForKey:(NSString *)key error:(int *)error options:(int)options;
- (int)removeExtendedAttributeForKey:(NSString *)key options:(int)options;
- (NSArray *)extendedAttributesList:(int *)error options:(int)options;
```

DFJPEGTurbo
-----------
Objective-C [libjpeg-turbo](http://libjpeg-turbo.virtualgl.org) wrapper (JPEG image codec that uses SIMD instructions (MMX, SSE2, NEON) to accelerate baseline JPEG compression and decompression on x86, x86-64, and ARM systems).

Key features:
- JPEG decompression with optional scaling

```objective-c
+ (UIImage *)jpegImageWithData:(NSData *)data;
+ (UIImage *)jpegImageWithData:(NSData *)data
                   orientation:(UIImageOrientation)orientation;
+ (UIImage *)jpegImageWithData:(NSData *)data
                   orientation:(UIImageOrientation)orientation
                   desiredSize:(CGSize)desiredSize
                       scaling:(DFJPEGTurboScaling)scaling
                      rounding:(DFJPEGTurboRounding)rounding;
```
DFMapping
---------
Simple concept that helps to construct tables and collection views with dynamic cells.
DFBenchmark
-----------
Benchmark your code in terms of nanoseconds. Based on Apple's libdispatch benchmark implementation. Functions declared in mach_time.h are used to measure time (time is measured in processor cicles). Substracts the time benchmark implementation takes (for-loop, etc). Easy to use C API.
```c
uint64_t dwarf_benchmark(BOOL verbose, void (^block)(void));
uint64_t dwarf_benchmark_loop(uint32_t count, BOOL verbose, void (^block)(void));
```
DFCrypto
--------
Convenience functions producing hash values using common digest algorithms. All functions return hash values expressed as NSString representing hexademical number. For example, `dwarf_md5` produces 128-bit hash value and returns NSString with 32 digit hexademical number.
```c
extern NSString *dwarf_md5(const char *data, uint32_t length);
extern NSString *dwarf_sha1(const char *data, uint32_t length);
extern NSString *dwarf_sha224(const char *data, uint32_t length);
extern NSString *dwarf_sha256(const char *data, uint32_t length);
extern NSString *dwarf_sha384(const char *data, uint32_t length);
extern NSString *dwarf_sha512(const char *data, uint32_t length);
```
DFOptions
---------
Macroses that simplify work with `NS_OPTIONS`.

```objective-c
#define DF_OPTIONS_ENABLE(mask, option) 
#define DF_OPTIONS_DISABLE(mask, option)
#define DF_OPTIONS_IS_ENABLED(mask, option)
#define DF_OPTIONS_SET(mask, option, enabled)
#define DF_OPTIONS_STRING(mask)
```
DFObjCExtensions
----------------
`safe_cast(TYPE, object)` - analog of C++ `dynamic_cast`. Returns pointer of the desired class. Returns nil if `isKindOfClass:` returns NO.
Example:
```objective-c
NSDictionary *JSON = safe_cast(NSDictionary, response);
```
DFReusablePool
--------------
Supports object reuse. Helps to avoid unnecessery memory allocations.
Installation
------------
1. If you are going to use DwarfKit categories: In your project go to Target / Build Settings, search for "Other Linker Flags" and add '-ObjC'.

About DwarfKit
=========
DwarfKit is a set of highly reusable Objective-C (iOS/Mac OS X) classes and categories.
Requirements
------------
- ARC

DFImageFetchManager
-------------------
Image fetching with extreme performance. 

Key features:
 - Performance and scalability. Built entirely on top of GCD. DFImageFetchManager is able to maintain thousands of image requests/request cancellations per second. Even on older devices.
 - JPEG images are decompressed via libjpeg-turbo. JPEG decompression is 3-4 times faster then iOS codec.
 - Fully customizable cache (you can provide custom cache implementation or even use NSURLCache, cache implementation can be changed for the particular request, etc).
 - Resources with the same URL are never downloaded twice.

DFCache
-------
 Efficient memory and disk key-value storage.
 
 Key features:
 - General purpose. Store any Objective-C objects. Built-in support for `UIImage` and `<NSCodying>` objects. 
 - Metadata. Read/write entry's metadata at any time. Add your custom key-values.
 - Performance. Synchronization based on reader-writer pattern makes all metadata and disk read operation concurrent and fast. Image caching performance is fantastic due to [libjpeg-turbo](http://libjpeg-turbo.virtualgl.org) which is used under the hood. Disk cache faults are handled instantly without disk I/O.
 - LRU cleanup.
 - Thread safety. 
 
Quick example of cache usage:
```objective-c
[cache storeObject:image forKey:@"key" data:data transform:^NSData *(id object) {
    return UIImageJPEGRepresentation(object, 1.0); // Isn't used since we provided data.
}];
    
[cache setMetadataValues:@{ @"UserKey" : @"UserValue" } forKey:@"key"];
    
NSDictionary *metadata = [cache metadataForKey:@"key"];
NSLog(@"Metadata: %@", metadata);

[cache objectForKey:@"key" queue:NULL transform:^id(NSData *data) {
    return [DFImageProcessing decompressedImageWithData:data];
} completion:^(id object) {
    // Display image
}];


2013-09-01 06:25:39.580 otest[1846:303] Metadata: {
    UserKey = UserValue;
    "_df_access_date" = "2013-09-01 02:25:39 +0000";
    "_df_creation_date" = "2013-09-01 02:25:39 +0000";
    "_df_expiration_date" = "2013-09-29 02:25:39 +0000";
    "_df_file_name" = 3c6e0b8a9c15224a8228b9a98ca1531d;
    "_df_file_size" = 59776;
}

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

DFBenchmark
---------
Benchmark your code in terms of nanoseconds. Functions declared in mach_time.h are used to measure time (time is measured in processor cicles). Substracts the time benchmark implementation takes (for-loop, etc). Easy to use C API.
```c
uint64_t dwarf_benchmark(BOOL verbose, void (^block)(void));
uint64_t dwarf_benchmark_loop(uint32_t count, BOOL verbose, void (^block)(void));
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
Installation
------------
1. If you are going to use DwarfKit categories: In your project go to Target / Build Settings, search for "Other Linker Flags" and add '-ObjC'.

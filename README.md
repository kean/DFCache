<p align="center"><img src="https://cloud.githubusercontent.com/assets/1567433/9701460/c779930e-5432-11e5-9c49-e4f00fef9770.png" height="100"/></p>

<p align="center">
<a href="https://cocoapods.org"><img src="https://img.shields.io/cocoapods/v/DFCache.svg"></a>
<a href="https://github.com/Carthage/Carthage"><img src="https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat"></a>
</p>

`DFCache` provides composite in-memory and on-disk cache with LRU cleanup. It is implemented as a set of reusable classes and protocols with concise and extensible API.

> `DFCache` is not intended to be used as a `NSURLCache` alternative. If you use `Foundation` URL loading system you should use `NSURLCache` that supports [HTTP Caching](https://tools.ietf.org/html/rfc7234).

## Features
- LRU cleanup (discards least recently used items first)
- Metadata implemented on top on UNIX extended file attributes
- Builtin support for objects conforming to `<NSCoding>` protocol. Can be easily extended to support more protocols and classes
- First class `UIImage` support including background image decompression
- Batch methods to retrieve cached entries
- Thoroughly tested and well-documented

## Requirements
iOS 6.0+ / watchOS 2.0+ / OS X 10.8+ / tvOS 9.0+

# Usage

### DFCache

#### Store, retrieve and remove object
```objective-c
DFCache *cache = [[DFCache alloc] initWithName:@"image_cache"];
NSString *key = @"http://..."; // Key can by any arbitrary string.
UIImage *image = ...; // Instead of UIImage you can use the same API for objects conforming to NSCoding protocol

// Store image
[cache storeObject:image forKey:key];
// [cache storeObject:image forKey:key data:data]; - you can store original image data

// Retrieve decompressed image
[cache cachedObjectForKey:key completion:^(id object) {
    // All disk IO operations are run on serial dispatch queue
    // which guarantees that the object is retrieved successfully.
    NSLog(@"Did retrieve cached object %@", object);
}];

[cache removeObjectForKey:key];
```

#### Set and read metadata
```objective-c
DFCache *cache = [[DFCache alloc] initWithName:@"sample_cache"];
NSDictionary *object = @{ @"key" : @"value" };
[cache storeObject:object forKey:@"key"];
[cache setMetadata:@{ @"revalidation_date" : [NSDate date] } forKey:@"key"];
NSDictionary *metadata = [cache metadataForKey:@"key"];
```

### DFCache (DFCacheExtended)

#### Retrieve batch of objects
```objective-c
DFCache *cache = ...;
[cache batchCachedObjectsForKeys:keys completion:^(NSDictionary *batch) {
    for (NSString *key in keys) {
        id object = batch[key];
        // Do something with an object.
    }
}];
```

### DFFileStorage

#### Write and read data
```objective-c
DFFileStorage *storage = [[DFFileStorage alloc] initWithPath:path error:nil];
[storage setData:data forKey:@"key"];
[storage dataForKey:@"key"];
```

#### Enumerate contents
```objective-c
DFFileStorage *storage = [[DFFileStorage alloc] initWithPath:path error:nil];
NSArray *resourceKeys = @[ NSURLContentModificationDateKey, NSURLFileAllocatedSizeKey ];
NSArray *contents = [storage contentsWithResourceKeys:resourceKeys];
for (NSURL *fileURL in contents) {
    // Use file URL and pre-fetched file attributes.
}
```

### NSURL (DFExtendedFileAttributes)

#### Set and read extended file attributes
```objective-c
NSURL *fileURL = [NSURL fileURLWithPath:path];
[fileURL df_setExtendedAttributeValue:@"value" forKey:@"attr_key"];
NSString *value = [fileURL df_extendedAttributeValueForKey:@"attr_key" error:NULL];
[fileURL df_removeExtendedAttributeForKey];
```

## Design
|Class|Description|
|---------|---------|
|[DFCache](https://github.com/kean/DFCache/blob/master/DFCache/DFCache.h)|Asynchronous composite in-memory and on-disk cache with LRU cleanup. Uses `NSCache` for in-memory caching and `DFDiskCache` for on-disk caching. Provides API for associating metadata with cache entries.|
|[\<DFValueTransforming\>](https://github.com/kean/DFCache/blob/master/DFCache/Transforming/DFValueTransformer.h)|Protocol for describing a way of encoding and decoding objects.|
|[\<DFValueTransformerFactory\>](https://github.com/kean/DFCache/blob/master/DFCache/Transforming/DFValueTransformerFactory.h)|Protocol for matching objects with value transformers.|
|[DFFileStorage](https://github.com/kean/DFCache/blob/master/DFCache/Key-Value%20File%20Storage/DFFileStorage.h)|Key-value file storage.|
|[DFDiskCache](https://github.com/kean/DFCache/blob/master/DFCache/DFDiskCache.h)|Disk cache extends file storage functionality by providing LRU (least recently used) cleanup.|
|[NSURL (DFExtendedFileAttributes)](https://github.com/kean/DFCache/blob/master/DFCache/Extended%20File%20Attributes/NSURL%2BDFExtendedFileAttributes.h)|Objective-c wrapper of UNIX extended file attributes. Extended attributes extend the basic attributes associated with files and directories in the file system. They are stored as name:data pairs associated with file system objects (files, directories, symlinks, etc). See setxattr(2).|
|[DFCache (DFCacheExtended)](https://github.com/kean/DFCache/blob/master/DFCache/DFCache%2BDFExtensions.h)|Set of methods that extend `DFCache` functionality by allowing you to retrieve cached entries in batches.|

### NSCache on iOS 7.0
`NSCache` auto-removal policies have change with the release of iOS 7.0. Make sure that you use reasonable total cost limit or count limit. Or else `NSCache` won't be able to evict memory properly. Typically, the obvious cost is the size of the object in bytes. Keep in mind that `DFCache` automatically removes all object from memory cache on memory warning for you.

## Installation

### [CocoaPods](http://cocoapods.org)

To install DFCache add a dependency to your Podfile:
```ruby
# source 'https://github.com/CocoaPods/Specs.git'
# use_frameworks!
# platform :ios, "6.0" / :watchos, "2.0" / :osx, "10.8" / :tvos, "9.0"

pod "DFCache"
```

### [Carthage](https://github.com/Carthage/Carthage)

To install DFCache add a dependency to your Cartfile:
```
github "kean/DFCache"
```

## Contacts

<a href="https://github.com/kean">
<img src="https://cloud.githubusercontent.com/assets/1567433/6521218/9c7e2502-c378-11e4-9431-c7255cf39577.png" height="44" hspace="2"/>
</a>
<a href="https://twitter.com/a_grebenyuk">
<img src="https://cloud.githubusercontent.com/assets/1567433/6521243/fb085da4-c378-11e4-973e-1eeeac4b5ba5.png" height="44" hspace="2"/>
</a>
<a href="https://www.linkedin.com/pub/alexander-grebenyuk/83/b43/3a0">
<img src="https://cloud.githubusercontent.com/assets/1567433/6521256/20247bc2-c379-11e4-8e9e-417123debb8c.png" height="44" hspace="2"/>
</a>

# License
DFCache is available under the MIT license. See the LICENSE file for more info.

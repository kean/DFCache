# About DFCache

DFCache is an iOS and OS X library that implements composite in-memory and on-disk cache. It is implemented as a set of reusable classes with concise and extensible API.

### Key Features
 - Encoding, decoding and cost calculation implemented using blocks. Store any kind of Objective-C objects or manipulate data directly (see `DFFileStorage`).
 - LRU cleanup (discards least recently used items first).
 - Custom metadata implemented on top on UNIX extended file attributes.
 - Thoroughly tested. Written for and used heavily in the iOS application with more than half a million active users.
 - Concise and extensible API.

### Requirements
- iOS 6.0 or OS X 10.7

### Current Version
Current version is 1.1.0.

# Classes
|Class|Description|
|---------|---------|
|[`DFCache`](https://github.com/kean/DFCache/blob/master/DFCache/DFCache.h)|Asynchronous composite in-memory and on-disk cache. Uses `NSCache` for in-memory caching and `DFDiskCache` for on-disk caching. Extends `DFDiskCache` functionality by providing API for associating custom metadata with cache entries.|
|[`DFCache (DFExtensions)`](https://github.com/kean/DFCache/blob/master/DFCache/DFCache%2BDFExtensions.h)|Set of methods that extend `DFCache` functionality by providing direct asynchronous access to data and allowing you to retrieve cached objects in batches.|
|[`DFFileStorage`](https://github.com/kean/DFCache/blob/master/DFCache/Key-Value%20File%20Storage/DFFileStorage.h)|Key-value file storage.|
|[`DFDiskCache`](https://github.com/kean/DFCache/blob/master/DFCache/DFDiskCache.h)|Disk cache extends file storage functionality by providing LRU (least recently used) cleanup.|
|[`NSURL (DFExtendedFileAttributes)`](https://github.com/kean/DFCache/blob/master/DFCache/Extended%20File%20Attributes/NSURL%2BDFExtendedFileAttributes.h)|Objective-c wrapper of UNIX extended file attributes. Extended attributes extend the basic attributes associated with files and directories in the file system. They are stored as name:data pairs associated with file system objects (files, directories, symlinks, etc). See setxattr(2).|

# Examples

### DFCache

#### Store, retreive and remove JSON
```objective-c
DFCache *cache = [[DFCache alloc] initWithName:@"sample_cache"];
NSData *data = ...; // Original JSON data.
id JSON = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
[cache storeObject:JSON forKey:key cost:0 data:data];

// Retreive object be decoding it using built-in DFCacheDecodeJSON block.
[cache cachedObjectForKey:key decode:DFCacheDecodeJSON cost:nil completion:^(id object) {
    // All cache disk IO operations are executed on the serial dispath queue
    // which guarantees that the object is going to be on disk.
    NSLog(@"Did retreive value %@ for key %@", object, key);
}];

[cache removeObjectForKey:key];
```

#### Set and read metadata
```objective-c
DFCache *cache = [[DFCache alloc] initWithName:@"sample_cache"];
NSDictionary *object = @{ @"key" : @"value" }
[cache storeObject:object forKey:key cost:0 data:DFCacheEncodeNSCoding];
[cache setMetadata:@{ @"revalidation_date" : [NSDate date] } forKey:key];
NSDictionary *metadata = [cache metadataForKey:key];
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

#### Set and read extended file attribute.
```objective-c
NSURL *fileURL = [NSURL fileURLWithPath:path];
[fileURL setExtendedAttributeValue:@"value" forKey:@"attr_key"];
NSString *value = [fileURL extendedAttributeValueForKey:@"attr_key" error:NULL];
```

# Installation

### Cocoapods
The recommended way to install `DFCache` is via [Cocoapods](http://cocoapods.org) package manager.
```ruby
# Podfile example
platform :ios, '6.0'
# platform :osx, '10.7'
pod 'DFCache', '~> 1.0'
```

# Contacts
[Alexander Grebenyuk](https://github.com/kean)

# License
DFCache is available under the MIT license. See the LICENSE file for more info.

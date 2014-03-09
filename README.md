# About DFCache

DFCache is an iOS and OS X library that implements composite in-memory and on-disk cache. It is implemented as a set of reusable classes with concise and extensible API.

### Key Features
 - Encoding, decoding and cost calculation implemented using blocks. Store any kind of Objective-C objects or manipulate data directly (see `DFFileStorage`).
 - LRU cleanup (discard least recently used items first).
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

# Installation

### Cocoapods
The recommended way to install `DFCache` is via [Cocoapods](http://cocoapods.org) package manager.
```ruby
# Podfile example
platform :ios, '6.0'
# platform :osx, '10.7'
pod "DFCache", "~> 1.0"
```

### Building static (iOS or OS X) or dynamic (OS X) library
The other way to install `DFCache` is by building static or dynamic library. `DFCache` Xcode project has everything you need in order to do that. Just select the required scheme and archive the product.

If you want to use iOS static library on both device and simulator you should build a 'fat' library. Unfortunately, Xcode doesn't have an option to build iOS static library for both ARM (device) and i386 (simulator) architectures.  Fortunately, there are [other ways](https://www.google.com/search?q=build+ios+static+library+for+both+device+and+simulator) to do that.

# License
DFCache is available under the MIT license. See the LICENSE file for more info.

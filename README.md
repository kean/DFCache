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

# Classes

### DFCache
Asynchronous composite in-memory and on-disk cache. Uses `NSCache` for in-memory caching and `DFDiskCache` for on-disk caching. Extends `DFDiskCache` functionality by providing API for associating custom metadata with cache entries.

### DFCache (DFExtensions)
Set of methods that extend `DFCache` functionality by providing direct asynchronous access to data and allowing you to retrieve cached objects in batches.

### DFFileStorage
Key-value file storage.

### DFDiskCache
Disk cache extends file storage functionality by providing LRU (least recently used) cleanup.

### NSURL (DFExtendedFileAttributes)
Objective-c wrapper of UNIX extended file attributes. Extended attributes extend the basic attributes associated with files and directories in the file system. They are stored as name:data pairs associated with file system objects (files, directories, symlinks, etc). See setxattr(2).

# Installation
DFCache can be installed via [Cocoapods](http://cocoapods.org).
#### Podfile
```ruby
platform :ios, '6.0'
pod "DFCache", "~> 1.0.0"
```

License
-------
DFCache is available under the MIT license. See the LICENSE file for more info.

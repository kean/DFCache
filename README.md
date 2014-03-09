About DFCache
=============
DFCache is an efficient memory and disk key-value storage built on top of NSCache and DFDiskCache. Key features:
- Encoding/decoding is implemented using blocks. Store any kind of Objective-C objects or manipulate data directly (see DFFileStorage)
- Custom metadata implemented on top on UNIX extended file attributes
- LRU cleanup (discard least recently used items first)
- Concise and extandable API

DFFileStorage
-------------
Key-value file storage.

NSURL (DFExtendedFileAttributes)
------------------------------
Objective-c wrapper of UNIX extended file attributes. Extended attributes extend the basic attributes associated with files and directories in the file system. They are stored as name:data pairs associated with file system objects (files, directories, symlinks, etc). See setxattr(2).

Installation
------------
DFCache can be installed via [Cocoapods](http://cocoapods.org).
#### Podfile
```ruby
platform :ios, '6.0'
pod "DFCache", "~> 1.0.0"
```

License
-------
DFCache is available under the MIT license.

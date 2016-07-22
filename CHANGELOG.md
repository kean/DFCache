[All releases](https://github.com/kean/DFCache/releases)

## DFCache 4.0.1

- Update for Xcode 8
- Fix `-init()` annotations for `DFDiskCache` and `DFCache`
- `-[DFValueTransformerFactory valueTransformerForName:]` argument `name` is now `nullable`


## DFCache 4.0
 
- Add CocoaPods support for tvOS, watchOS
- Add Carthage support for OSX, tvOS, watchOS
- #5 Update DFCacheImageDecoder with code from DFImageManager
- Remove prefix headers
- Remove targets that build libraries in favour of frameworks
- Replace outdated `#if __IPHONE_OS_VERSION_MIN_REQUIRED`
- Remove per-test target info.plist files
- Remove obsolete RunUnitTests script from test bundle
- Add Swift playground


## DFCache 3.1.1
 
Adapt for Xcode 7
 
 
## DFCache 3.1.0
 
DFCache now works great with Swift thanks to new nullability annotations. The internals haven't change so it's still safe to pass nil in methods that used to work with nil arguments but are marked nonnull now. However, make sure that the way you use DFCache API complies with the new requirements.
 
 
## DFCache 3.0.1
 
- Use float instead of CGFloat (@bretdabaker, #2)


## DFCache 3.0.0
 
- `DFCache` now stores value transformer names in files’ metadata instead of encoded value transformer. `DFCache 3.0` won't be able to reverse transform objects created by previous versions of `DFCache`, but it will delete them automatically using built-in LRU algorithm;
- Change `<DFValueTransformerFactory>` methods to return value transformer name for object instead of value transformer itself. Add method to return value transformer for a given name;
- `DFValueTransformerFactory` now allows users to register value transformers for names. Registers all built-in value transformers automatically;
- Remove all methods that include `id<DFValueTransforming>` from `DFCache` interface. Simplify `DFCache` implementation;
- `<DFValueTransforming>` no longer requires `<NSCoding>` protocol.
- Add `allowsImageDecompression` property to `DFValueTransformerUIImage`. Add the same property to `DFCache` via category.
- `DFCache` uses `NSURL` to prevent excessful hash computations
- Rewrite tests to use `XCTestExpectation`, remove `DFTesting`. Remove obsolete tests.


## DFCache 2.0.1
 
- Improve `DFCache` implementation.
- Async read methods will no longer crash when called without a completion block. But it will still "preheat" objects.
- `DFCache` no longer catches value transformers exceptions. Client are responsible for providing valid transformers.
 
 
## DFCache 2.0.0
 
- All new API built on top of a new family of protocols (`<DFValueTransforming>`, `<DFValueTransformerFactory>`). `DFCache` methods are much easier to use now. Storing and retrieving objects is as simple as calling `-storeObject:forKey:` and `-cachedObjectForKey:`. You don't have to provide encoding, decoding and cost calculating blocks like in previous versions, `DFCache` automatically picks the appropriate value transformers for you during both encoding and decoding.
-  There is much more room for customizing encoding and decoding behavior. It's easy to add support for new classes using `<DFValueTransformerFactory>` protocol. And it's easy to write elaborate value transformers.
- `UIImage` is now directly supported by default `DFCache` methods. There is no need to import any additional headers. `DFCache (UIImage)` category was removed.
- Images that have alpha channel are now automatically serialized using `UIImagePNGRepresentation` method.
- You can now modify JPEG compression quality.
- Initializing `DFCache` without disk cache no longer raises an exception so that you can use `DFCache` API solely for memory caching features like automatic objects cost management and cleanup on memory warnings.
- Easier to use batch API. Batch methods were rewritten from scratch and are now based exclusively on standard `DFCache` methods.
- Add prefixes to methods in `NSURL (DFExtendedFileAttributes)` category, since this feature became very popular and there is an increasing number of projects that add similar methods.
- Convert to modern Objective-C. Initializes now return `instancetype` instead of `id`. Mark designated methods with a specific attribute.
- `ioQueue` and `processingQueue` are no longer part of public `DFCache` interface, concurrency implementation may change in future versions!

 
## DFCache 1.3.3
 
- Improved encoding and decoding stability
 
 
## DFCache 1.3.2
 
- Use CGImageGetBitsPerPixel for image cost calculation
- Use kCGImageSourceShouldCacheImmediately on iOS 7 (code is commented out for now)


## DFCache 1.3.1
 
- Data manipulation methods moved from DFCacheExtensions category to primary DFCache interface
- Improved and extended batch API (see DFCacheExtensions)
- Add debugDescription (DFCache, DFDiskCache, DFFileStorage)
- Vasty improved documentation.

 
## DFCache 1.3.0
 
- DFCache automatically removes all objects from memory cache on UIApplicationDidReceiveMemoryWarningNotification notification.
- DFCache: cleaner interface for storing and retrieving entries. Deprecate two clumsy methods.
- DFDiskCache: add initWithName: method.
- DFDiskCache: default capacity is now 100 Mb instead of DFDiskCacheCapacityUnlimited.
- Improved documentation.


## DFCache 1.2.1

- DFDiskCache now uses built-in NSURLContentAccessDateKey for LRU cleanup


## DFCache 1.2.0

- Add first class UIImage support, including background image decompression


## DFCache 1.1.0

- Add cleanup scheduling API


## DFCache 1.0.0
 
- Initial public version.

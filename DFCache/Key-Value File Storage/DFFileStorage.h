// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*! Key-value file storage.
 @discussion File storage doesn't limit your access to the underlying storage directory.
 */
@interface DFFileStorage : NSObject

/*! Initializes and returns storage with the given directory path.
 @param path Storage directory path.
 @param error A pointer to an error object. If an error occurs while creating storage directory, the pointer is set to the file system error (see NSFileManager). You may specify nil for this parameter if you do not want the error information.
 */
- (instancetype)initWithPath:(NSString *)path error:(NSError **)error NS_DESIGNATED_INITIALIZER;

/*! Unavailable initializer, please use designated initializer.
 */
- (instancetype)init NS_UNAVAILABLE;

/*! Returns storage directory path.
 */
@property (nonatomic, readonly) NSString *path;

/*! Returns the contents of the file for the given key.
 */
- (nullable NSData *)dataForKey:(NSString *)key;

/*! Creates a file with the specified content for the given key.
 */
- (void)setData:(NSData *)data forKey:(NSString *)key;

/*! Removes the file for the given key.
 */
- (void)removeDataForKey:(NSString *)key;

/*! Removes all storage contents.
 */
- (void)removeAllData;

/*! Returns a boolean value that indicates whether a file exists for the given key.
 */
- (BOOL)containsDataForKey:(NSString *)key;

/*! Returns file name for the given key.
 */
- (NSString *)filenameForKey:(NSString *)key;

/*! Returns file path for the given key.
 */
- (NSString *)pathForKey:(NSString *)key;

/* Returns file URL for the given key.
 */
- (NSURL *)URLForKey:(NSString *)key;

/*! Returns the current size of the receiver contents, in bytes.
 */
- (unsigned long long)contentsSize;

/*! Returns URLs of items contained into storage.
 @param keys An array of keys that identify the file properties that you want pre-fetched for each item in the storage. For each returned URL, the specified properties are fetched and cached in the NSURL object. For a list of keys you can specify, see Common File System Resource Keys.
 */
- (nullable NSArray *)contentsWithResourceKeys:(nullable NSArray *)keys;

@end

NS_ASSUME_NONNULL_END

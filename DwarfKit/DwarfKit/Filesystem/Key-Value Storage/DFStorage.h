/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

static const unsigned long long DFStorageDiskCapacityUnlimited = 0;

/** Key-value file storage with LRU cleanup (when you need it).
 */
NS_CLASS_AVAILABLE(10_7, 5_0)
@interface DFStorage : NSObject

/** Initializes and returns cache with provided root folder path.
 @param path Storage root folder path.
 */
- (id)initWithPath:(NSString *)path;

/** Returns storage root folder path.
 */
@property (nonatomic, readonly) NSString *path;

/** Maximum storage capacity. If 0 then disk space is unlimited.
 @discussion Not a strict limit. Disk storage is actually cleaned up each time application resigns active (for iOS) and any time - (void)cleanup gets called.
 */
@property (nonatomic) unsigned long long diskCapacity;

/** Remaining disk usage after cleanup. The rate must be in the range of 0.0 to 1.0 where 1.0 represents full disk capacity.
 */
@property (nonatomic) CGFloat cleanupRate;

#pragma mark - Read

/** Reads data from disk.
 @param key The unique key.
 @param completion Completion block.
 */
- (void)readDataForKey:(NSString *)key completion:(void (^)(NSData *data))completion;

/** Reads data from disk synchronously.
 @param key The unique key.
 */
- (NSData *)readDataForKey:(NSString *)key;

/** Reads multiple NSData objects for provided keys.
 @param keys Array of unique keys.
 @param completion Completion block.
 */
- (void)readBatchForKeys:(NSArray *)keys completion:(void (^)(NSDictionary *batch))completion;

/** Returns YES if storage contains data for provided key.
 */
- (BOOL)containsDataForKey:(NSString *)key;

#pragma mark - Write

/** Writes data into disk storage asyncronously.
 @param data Data to store into disk cache.
 @param key The unique key.
 */
- (void)writeData:(NSData *)data forKey:(NSString *)key;

/** Writes data into disk storage synchronously.
 @param data Data to store into disk cache.
 @param key The unique key.
 */
- (void)writeDataSynchronously:(NSData *)data forKey:(NSString *)key;

/** Writes batch of NSData objects into disk cache.
 @param batch Dictionary containing { key : data }.
 @param completion Completion block.
 */
- (void)writeBatch:(NSDictionary *)batch;

#pragma mark - Remove

/** Deletes data from storage.
 */
- (void)removeDataForKeys:(NSArray *)keys;
- (void)removeDataForKey:(NSString *)key;
- (void)removeAllData;

#pragma mark - Maintenance

/** Returns the current size of the receiver contents, in bytes.
 */
- (unsigned long long)contentsSize;

/** Returns URLs of items contained into storage.
 @param keys An array of keys that identify the file properties that you want pre-fetched for each item in the storage. For each returned URL, the specified properties are fetched and cached in the NSURL object. For a list of keys you can specify, see Common File System Resource Keys.
 */
- (NSArray *)contentsWithResourceKeys:(NSArray *)keys;

/** Cleans up disk by removing entries by LRU algorithm.
 @discussion Cleanup algorithm runs only if max disk cache capacity is set to non-zero value. Calculates target size by multiplying disk capacity and cleanup rate. Files are removed according to LRU algorithm until cache size fits target size.
 */
- (void)cleanup;

@end

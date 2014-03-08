/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

@class DFStorage;

@protocol DFStorageDelegate <NSObject>

- (void)storage:(DFStorage *)storage didReadFileAtURL:(NSURL *)fileURL;

@end


/*! Key-value file storage.
 */
NS_CLASS_AVAILABLE(10_6, 4_0)
@interface DFStorage : NSObject

/*! Initializes and returns storage with provided directory path.
 @param path Storage directory path.
 @param error A pointer to an error object. Might be nil.
 */
- (id)initWithPath:(NSString *)path error:(NSError *__autoreleasing *)error;

/*! Returns storage directory path.
 */
@property (nonatomic, readonly) NSString *path;

@property (nonatomic, weak) id<DFStorageDelegate> delegate;

- (NSData *)dataForKey:(NSString *)key;
- (void)setData:(NSData *)data forKey:(NSString *)key;
- (void)removeDataForKey:(NSString *)key;
- (void)removeAllData;
- (BOOL)containsDataForKey:(NSString *)key;

/*! Returns file name for key. File names are generated using SHA-1 digest algorithm.
 */
- (NSString *)fileNameForKey:(NSString *)key;
- (NSString *)filePathForKey:(NSString *)key;
- (NSURL *)fileURLForKey:(NSString *)key;

/*! Returns the current size of the receiver contents, in bytes.
 */
- (unsigned long long)contentsSize;

/*! Returns URLs of items contained into storage.
 @param keys An array of keys that identify the file properties that you want pre-fetched for each item in the storage. For each returned URL, the specified properties are fetched and cached in the NSURL object. For a list of keys you can specify, see Common File System Resource Keys.
 */
- (NSArray *)contentsWithResourceKeys:(NSArray *)keys;

@end

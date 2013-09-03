/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFImageCaching.h"
#import "DFNetworkingConstants.h"
#import "DFTask.h"


@interface DFImageFetchTask : DFTask

/*! Image URL image fetch task was initialized with.
 */
@property (nonatomic, strong, readonly) NSString *imageURL;

#pragma mark - Task Settings

/*! Cached used by image fetch task. If cache is nil then shared NSURLCache is used instead.
 @discussion Task is set by DFImageFetchManager. But you can change cache for any particular task.
 */
@property (nonatomic, strong) id<DFImageCaching> cache;

@property (nonatomic, copy) NSURLRequest *(^requestBlock)(NSString *, DFImageFetchTask *);
- (void)setRequestBlock:(NSURLRequest *(^)(NSString *imageURL, DFImageFetchTask *task))requestBlock;

#pragma mark - Task Output

@property (nonatomic, strong, readonly) UIImage *image;

/*! Source becomes invalid (is always DFResponseSourceWeb) when NSURLCache is used as a caching mechanism. Be aware. 
 */
@property (nonatomic, readonly) DFResponseSource source;
@property (nonatomic, strong, readonly) NSError *error;

- (id)initWithURL:(NSString *)imageURL;



@end

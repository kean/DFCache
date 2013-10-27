/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFTask.h"


@protocol DFImageFetchTaskDelegate;


typedef void (^DFImageFetchCaching)(UIImage *image, NSData *data, NSString *lastModified);


@interface DFImageFetchTask : DFTask

@property (nonatomic, weak) id<DFImageFetchTaskDelegate> delegate;
@property (nonatomic, readonly) NSString *imageURL;
@property (nonatomic, readonly) UIImage *image;
@property (nonatomic, readonly) NSData *data;
@property (nonatomic, readonly) NSHTTPURLResponse *response;
@property (nonatomic, readonly) NSError *error;
@property (nonatomic, readonly) BOOL notModified;

- (id)initWithURL:(NSString *)imageURL;
- (id)initWithURL:(NSString *)imageURL revalidate:(BOOL)revalidate ifModifiedSince:(NSString *)ifModifiedSince;

@end


@protocol DFImageFetchTaskDelegate

- (NSURLRequest *)requestForImageFetchingTask:(DFImageFetchTask *)task;
- (void)imageFetchTaskDidFinishProcessingImage:(DFImageFetchTask *)task;

@end
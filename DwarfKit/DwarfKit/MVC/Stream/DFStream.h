/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

@class DFStream;


@protocol DFStream <NSObject>

- (BOOL)poll;
- (void)cancel;
- (void)reset;
- (BOOL)isEnded;
- (BOOL)isPolling;

@end


@protocol DFStreamDelegate <NSObject>

- (void)streamDidStartPolling:(id<DFStream>)stream;
- (void)stream:(id<DFStream>)stream didRecieveData:(id)data userInfo:(id)userInfo;
- (void)stream:(id<DFStream>)stream didFailWithError:(NSError *)error userInfo:(id)userInfo;
- (void)streamDidCancel:(id<DFStream>)stream;
- (void)streamDidEnd:(id<DFStream>)stream;

@end


@protocol DFStreamDataProvider <NSObject>

- (void)poll:(DFStream *)stream;
- (void)cancel:(DFStream *)stream;

@end


@interface DFStream : NSObject <DFStream>

@property (nonatomic, weak) id<DFStreamDelegate> delegate;
@property (nonatomic, weak) id<DFStreamDataProvider> dataProvider;

- (void)processPolledData:(id)data isEnd:(BOOL)isEnd userInfo:(id)userInfo;
- (void)processPollError:(NSError *)error isEnd:(BOOL)isEnd userInfo:(id)userInfo;

@end

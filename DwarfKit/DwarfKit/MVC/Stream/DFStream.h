//
//  DFPager.h
//  DwarfKit
//
//  Created by Alexander Grebenyuk on 10/1/13.
//  Copyright (c) 2013 com.github.kean. All rights reserved.
//

#import <Foundation/Foundation.h>


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

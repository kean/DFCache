//
//  DFPagerChain.h
//  DwarfKit
//
//  Created by Alexander Grebenyuk on 10/1/13.
//  Copyright (c) 2013 com.github.kean. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DFStream.h"

@interface DFStreamChain : NSObject <DFStream>

- (id)initWithStream:(id<DFStream>)stream;
- (void)addStream:(id<DFStream>)stream;

@end

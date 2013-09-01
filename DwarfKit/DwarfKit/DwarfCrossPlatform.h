//
//  DwarfCrossPlatform.h
//  DwarfKit
//
//  Created by Alexander Grebenyuk on 02.09.13.
//  Copyright (c) 2013 Alexander Grebenyuk. All rights reserved.
//

#if TARGET_OS_IPHONE

#define DFApplicationWillResignActiveNotification   UIApplicationWillResignActiveNotification
#define DFApplicationWillTerminateNotification  UIApplicationWillTerminateNotification

#else

#define DFApplicationWillResignActiveNotification   NSApplicationWillResignActiveNotification
#define DFApplicationWillTerminateNotification  NSApplicationWillTerminateNotification


#endif

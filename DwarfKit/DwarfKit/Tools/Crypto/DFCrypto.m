//
//  DFCrypto.m
//  Dwarf
//
//  Created by Alexander Grebenyuk on 7/20/13.
//  Copyright (c) 2013 Alexander Grebenyuk. All rights reserved.
//

#import "DFCrypto.h"
#import <CommonCrypto/CommonCrypto.h>


@implementation DFCrypto

+ (NSString *)MD5FromString:(NSString *)string {
   if (string.length > 0) {
      const char *data = [string UTF8String];
      unsigned char md5[CC_MD5_DIGEST_LENGTH];
      CC_MD5(data, (CC_LONG)strlen(data), md5);
      
      // TODO: Rewrite in C
      NSMutableString *hash = [NSMutableString string];
      for (size_t i = 0 ; i < CC_MD5_DIGEST_LENGTH ; i++) {
         [hash appendFormat:@"%02x", md5[i]];
      }
      
      return hash;
   }
   return nil;
}

@end

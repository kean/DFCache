/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

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

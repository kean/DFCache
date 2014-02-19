/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFURLRequestConstructor.h"

static inline NSString *_DFURLParameterStringValue(id parameter) {
   if ([parameter isKindOfClass:[NSString class]]) {
      return parameter;
   }
   if ([parameter isKindOfClass:[NSNumber class]]) {
      return [parameter stringValue];
   }
   return nil;
}

NSString *DFURLQueryStringFromParameters(NSDictionary *parameters, DFURLQueryConstructionOptions options) {
   if (!parameters.count) {
      return nil;
   }
   NSMutableArray *pairs = [NSMutableArray new];
   NSArray *keys = [parameters allKeys];
   if (options & DFURLQueryConstructionSortedKeys) {
      keys = [keys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
   }
   for (NSString *key in parameters) {
      if (![key isKindOfClass:[NSString class]]) {
         [NSException raise:NSInvalidArgumentException format:@"Attempting to construct query from non-string key, %@", key];
      }
      NSString *parameter = _DFURLParameterStringValue(parameters[key]);
      if (!parameter) {
         [NSException raise:NSInvalidArgumentException format:@"Attempting to construct query with invalid parameter, %@", parameters[key]];
      }
      [pairs addObject:[NSString stringWithFormat:@"%@=%@", DFURLPercentEscapedString(key), DFURLPercentEscapedString(parameter)]];
   }
   return [pairs componentsJoinedByString:@"&"];
}

NSString *DFURLPercentEscapedString(NSString *string) {
   return (__bridge_transfer NSString *)(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)(string), NULL, (__bridge CFStringRef)kDFURLReservedCharacters_RFC3986, kCFStringEncodingUTF8));
}

extern NSString *DFURLJSONStringFromObject(id object) {
   NSData *data = [NSJSONSerialization dataWithJSONObject:object options:kNilOptions error:nil];
   return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}


@implementation DFURLHTTPRequestConstructor

- (id)init {
   if (self = [super init]) {
      _HTTPHeaders = [NSMutableDictionary new];
      _HTTPMethodsEncodingParametersInURI = [NSMutableSet setWithObjects:@"GET", @"HEAD", @"DELETE", nil];
   }
   return self;
}

#pragma mark - <DFURLRequestConstructor>

- (NSURLRequest *)requestWithRequest:(NSURLRequest *)request parameters:(NSDictionary *)parameters error:(NSError *__autoreleasing *)error {
   NSParameterAssert(request);
   NSMutableURLRequest *mutableRequest = [request mutableCopy];
   for (NSString *field in _HTTPHeaders) {
      if (![mutableRequest valueForHTTPHeaderField:field]) {
         [mutableRequest setValue:_HTTPHeaders[field] forHTTPHeaderField:field];
      }
   }
   if (!parameters.count) {
      return mutableRequest;
   }
   NSString *query = DFURLQueryStringFromParameters(parameters, _queryOptions);
   if ([self.HTTPMethodsEncodingParametersInURI containsObject:[[request HTTPMethod] uppercaseString]]) {
      mutableRequest.URL = [NSURL URLWithString:[[mutableRequest.URL absoluteString] stringByAppendingFormat:mutableRequest.URL.query ? @"&%@" : @"?%@", query]];
   } else {
      if (![mutableRequest valueForHTTPHeaderField:@"Content-Type"]) {
         NSString *charset = (__bridge NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
         [mutableRequest setValue:[NSString stringWithFormat:@"application/x-www-form-urlencoded; charset=%@", charset] forHTTPHeaderField:@"Content-Type"];
      }
      [mutableRequest setHTTPBody:[query dataUsingEncoding:NSUTF8StringEncoding]];
   }
   return mutableRequest;
}

#pragma mark - <NSCopying>

- (id)copyWithZone:(NSZone *)zone {
   DFURLHTTPRequestConstructor *constructor = [DFURLHTTPRequestConstructor new];
   constructor.HTTPHeaders = _HTTPHeaders;
   constructor.HTTPMethodsEncodingParametersInURI = _HTTPMethodsEncodingParametersInURI;
   constructor.queryOptions = _queryOptions;
   return constructor;
}

@end

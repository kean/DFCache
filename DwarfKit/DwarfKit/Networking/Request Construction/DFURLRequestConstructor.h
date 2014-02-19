/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

typedef NS_OPTIONS(NSUInteger, DFURLQueryConstructionOptions) {
   DFURLQueryConstructionSortedKeys = 1 << 0,
};

extern NSString *DFURLQueryStringFromParameters(NSDictionary *parameters, DFURLQueryConstructionOptions options);

extern NSString *DFURLPercentEscapedString(NSString *string);

static NSString *kDFURLReservedCharacters_RFC3986 = @"!*'();:@&=+$,/?#[]";

extern NSString *DFURLJSONStringFromObject(id object);


@protocol DFURLRequestConstructing <NSObject>

- (NSURLRequest *)requestWithRequest:(NSURLRequest *)request parameters:(NSDictionary *)parameters error:(NSError *__autoreleasing *)error;

@end


@interface DFURLHTTPRequestConstructor : NSObject <DFURLRequestConstructing, NSCopying>

@property (nonatomic) NSMutableDictionary *HTTPHeaders;

/*! By default "GET", "HEAD", "DELETE" will put parameters into URL query string. Other HTTP methods will put paremeters into HTTP body.
 */
@property (nonatomic) NSMutableSet *HTTPMethodsEncodingParametersInURI;

@property (nonatomic) DFURLQueryConstructionOptions queryOptions;

@end

/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFURLSessionResponse.h"

@implementation DFURLSessionResponse

- (id)initWithObject:(id)object response:(NSURLResponse *)response data:(NSData *)data userInfo:(NSDictionary *)userInfo {
    if (self = [super init]) {
        _object = object;
        _response = response;
        _data = data;
        _userInfo = userInfo;
    }
    return self;
}

- (id)initWithObject:(id)object response:(NSURLResponse *)response data:(NSData *)data {
    return [self initWithObject:object response:response data:data userInfo:nil];
}

@end


@implementation DFURLSessionResponse (HTTP)

- (NSHTTPURLResponse *)HTTPResponse {
    if ([self.response isKindOfClass:[NSHTTPURLResponse class]]) {
        return (id)self.response;
    }
    return nil;
}

@end


@implementation DFURLSessionResponse (DataRepresentation)

- (NSStringEncoding)textEncoding {
    NSStringEncoding encoding = NSUTF8StringEncoding;
    if (_response.textEncodingName.length) {
        CFStringEncoding c_encoding = CFStringConvertIANACharSetNameToEncoding((__bridge CFStringRef)(_response.textEncodingName));
        if (c_encoding != kCFStringEncodingInvalidId) {
            encoding = CFStringConvertEncodingToNSStringEncoding(c_encoding);
        }
    }
    return encoding;
}

- (NSString *)stringRepresentation {
    return [[NSString alloc] initWithData:_data encoding:[self textEncoding]];
}

- (NSString *)JSONRepresentation {
    return [self JSONRepresentationWithError:nil];
}

- (NSString *)JSONRepresentationWithError:(NSError *__autoreleasing *)err {
    NSData *data = _data;
    if ([self textEncoding] != NSUTF8StringEncoding) {
        data = [[self stringRepresentation] dataUsingEncoding:NSUTF8StringEncoding];
    }
    NSError *error;
    id JSON = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    if (err) {
        *err = error;
    }
    return JSON;
}

@end

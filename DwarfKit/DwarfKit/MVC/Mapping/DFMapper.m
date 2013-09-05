/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFMapper.h"

@implementation DFMapper {
    NSDictionary *_scheme;
}

- (id)initWithScheme:(NSDictionary *)scheme {
    if (self = [super init]) {
        _scheme = scheme;
    }
    return self;
}

- (Class)cellClassForItem:(id)item atIndexPath:(NSIndexPath *)indexPath {
    NSAssert(item, @"%@ failure: entity must not be nil", NSStringFromSelector(_cmd));
    NSString *entityClassString = NSStringFromClass([item class]);
    NSString *cellClassString = _scheme[entityClassString];
    NSAssert(cellClassString, @"%@ failure: failed to resolve cell class for %@ entity", NSStringFromSelector(_cmd), entityClassString);
    Class cellClass = NSClassFromString(cellClassString);
    NSAssert(cellClass, @"%@ failure: no loaded class with name %@", NSStringFromSelector(_cmd), cellClassString);
    return cellClass;
}

@end

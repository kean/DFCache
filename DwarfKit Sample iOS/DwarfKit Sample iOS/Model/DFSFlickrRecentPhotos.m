/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFSFlickrRecentPhotos.h"
#import "DFSFlickrPhoto.h"


@implementation DFSFlickrRecentPhotos {
    NSMutableArray *_photos;
}


- (id)init {
    if (self = [super init]) {
        _photos = [NSMutableArray new];
    }
    return self;
}

- (void)loadPhotosWithPageCount:(NSUInteger)pageCount completion:(void (^)(void))completion {
    [self _loadFlickrPhotosFromPage:1 toPage:pageCount completion:completion];
}


- (void)_loadFlickrPhotosFromPage:(NSUInteger)fromPage toPage:(NSUInteger)toPage completion:(void (^)(void))completion {
    if (fromPage > toPage) {
        _isLoaded = YES;
        completion();
    } else {
        [self _loadFlickrPhotosForPage:fromPage completion:^(NSArray *photos, NSUInteger page) {
            [_photos addObjectsFromArray:photos];
            [self _loadFlickrPhotosFromPage:(page + 1) toPage:toPage completion:completion];
        }];
    }
    
}


- (void)_loadFlickrPhotosForPage:(NSUInteger)page completion:(void (^)(NSArray *photos, NSUInteger page))completion {
    NSString *urlString = [NSString stringWithFormat:@"http://api.flickr.com/services/rest/?api_key=a292d5f86afcbab8b0b8161ecee51184&format=json&method=flickr.photos.getRecent&nojsoncallback=1&page=%i", page];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ( ! error) {
                NSMutableArray *photos = [NSMutableArray new];
                NSError *parseError;
                id JSON = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&parseError];
                if (!parseError) {
                    NSArray *responsePhotos = [JSON valueForKeyPath:@"photos.photo"];
                    for (id photoJSON in responsePhotos) {
                        DFSFlickrPhoto *photo = [[DFSFlickrPhoto alloc] initWithJSON:photoJSON];
                        [photos addObject:photo];
                    }
                    if (completion) {
                        completion(photos, page);
                    }
                }
            } else {
                [self _loadFlickrPhotosForPage:page completion:completion];
            }
        });
    }];
    
}

@end

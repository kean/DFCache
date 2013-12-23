/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFBenchmark.h"
#import "DFImageProcessing.h"
#import "SDFBenchmarkImageDecompression.h"
#import "SDWebImageDecoder.h"

@implementation SDFBenchmarkImageDecompression

- (void)run {
    UIImage *image = [UIImage imageNamed:@"sample-01.jpeg"];
    NSArray *images = @[ [DFImageProcessing imageWithImage:image scaledToSize:DFSizeScaled(image.size, 0.5f)], image, [DFImageProcessing imageWithImage:image scaledToSize:DFSizeScaled(image.size, 2.f)]];
    for (UIImage *image in images) {
        [self _benchmarkWithImage:image compressionQuality:0.33f];
        [self _benchmarkWithImage:image compressionQuality:0.66f];
        [self _benchmarkWithImage:image compressionQuality:1.f];
    }
}

- (void)_benchmarkWithImage:(UIImage *)image compressionQuality:(CGFloat)compressionQuality {
    NSLog(@"---------------------------------------------------");
    NSLog(@"Benchmarking jpeg decompression with image size: (%f, %f), compression quality: (%f)", image.size.width, image.size.height, compressionQuality);
    NSData *data = UIImageJPEGRepresentation(image, compressionQuality);
    NSLog(@"Benchmark: SDWebImageDecoder");
    dwarf_benchmark(YES, ^{
        @autoreleasepool {
            UIImage *image = [UIImage imageWithData:data];
            __attribute__((unused)) UIImage *decodedImage = [UIImage decodedImageWithImage:image];
        }
    });
    NSLog(@"Benchmark: DFImageProcessing");
    dwarf_benchmark(YES, ^{
        @autoreleasepool {
            __attribute__((unused)) UIImage *decodedImage = [DFImageProcessing decompressedImageWithData:data];
        }
    });
}

@end

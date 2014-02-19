/*
 The MIT License (MIT)
 
 Copyright (c) 2013 Alexander Grebenyuk (github.com/kean).
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "DFURLSession.h"
#import "DFImageView.h"
#import "SDFFlickrPhoto.h"
#import "SDFFlickrRecentPhotos.h"
#import "SDFImageFetchingStressTestViewController.h"
#import "SDFImagesStressTestTableCell.h"


@interface SDFImageFetchingStressTestViewController () <UITableViewDataSource, UITableViewDelegate>

@end


@implementation SDFImageFetchingStressTestViewController {
    UIActivityIndicatorView *_activityIndicatorView;
    UITableView *_tableView;
    CADisplayLink *_displayLink;
    SDFFlickrRecentPhotos *_recentPhotos;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        _recentPhotos = [SDFFlickrRecentPhotos new];
        self.title = @"Stress Test";
    }
    return self;
}

- (void)loadView {
    [super loadView];
    
    _activityIndicatorView = ({
        UIActivityIndicatorView *view = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        view.center = CGPointMake(CGRectGetWidth(self.view.bounds) / 2.0,
                                  CGRectGetHeight(self.view.bounds) / 2.0);
        view;
    });
    
    // UITableView is way more performant then UICollectionView
    _tableView = ({
        CGRect rect = CGRectMake(0.f, 0.f, self.view.bounds.size.width, self.view.bounds.size.height);
        UITableView *tableView = [[UITableView alloc] initWithFrame:rect style:UITableViewStylePlain];
        tableView.backgroundColor = [UIColor blackColor];
        tableView.delegate = self;
        tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        tableView.dataSource = self;
        tableView.showsVerticalScrollIndicator = NO;
        tableView;
    });
    
    [self.view addSubview:_tableView];
    [self.view addSubview:_activityIndicatorView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [_activityIndicatorView startAnimating];
    [_recentPhotos loadPhotosWithPageCount:12 completion:^{
        [_activityIndicatorView stopAnimating];
        [_tableView reloadData];
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
#warning NOT IMPLEMENTED
//    [[DFURLSession shared].queue cancelAllOperations];
}

#pragma mark - UITableViewDataSource & Delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _recentPhotos.photos.count / 16;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SDFImagesStressTestTableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"stresscell"];
    if (cell == nil) {
        cell = [[SDFImagesStressTestTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"stresscell"];
    }
    
    for (NSUInteger i = 0; i < 16; i++) {
        SDFFlickrPhoto *photo = [self _photoAtRow:indexPath.row offset:i];
        DFImageView *imageView = [cell.imageViews objectAtIndex:i];
        imageView.image = nil;
        [imageView setImageWithURL:photo.photoURLSmall];
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 20.f;
}

- (SDFFlickrPhoto *)_photoAtRow:(NSUInteger)row offset:(NSUInteger)offset {
    NSUInteger index = offset + row * 16;
    return [_recentPhotos.photos objectAtIndex:index];
}

@end

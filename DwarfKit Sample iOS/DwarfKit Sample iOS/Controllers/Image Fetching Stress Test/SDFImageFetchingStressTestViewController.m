//
//  SEImageManagerStressTestViewController.m
//  Dwarf
//
//  Created by Alexander Grebenyuk on 8/12/13.
//  Copyright (c) 2013 Alexander Grebenyuk. All rights reserved.
//

#import "DFImageView.h"
#import "SDFImageFetchManager.h"
#import "SDFImageView.h"
#import "DFSFlickrPhoto.h"
#import "DFSFlickrRecentPhotos.h"
#import "SDFImageFetchingStressTestViewController.h"
#import "SDFImagesStressTestTableCell.h"
#import <QuartzCore/QuartzCore.h>


@interface SDFImageFetchingStressTestViewController () <UITableViewDataSource, UITableViewDelegate>

@end


@implementation SDFImageFetchingStressTestViewController {
    UILabel *_infoLabel;
    UIActivityIndicatorView *_activityIndicatorView;
    UITableView *_tableView;
    CADisplayLink *_displayLink;
    DFSFlickrRecentPhotos *_recentPhotos;
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        _recentPhotos = [DFSFlickrRecentPhotos new];
        self.title = @"Stress Test";
    }
    return self;
}


- (void)loadView {
    [super loadView];
    
    _infoLabel = ({
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.f, 0.f, 320.f, 66.f)];
        label.numberOfLines = 0;
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:12.f];
        label.center = CGPointMake(self.view.bounds.size.width / 2.0, self.view.bounds.size.height - 22.f);
        label.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        label.backgroundColor = [UIColor blackColor];
        label.textColor = [UIColor whiteColor];
        label;
    });
    
    _activityIndicatorView = ({
        UIActivityIndicatorView *view = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        view.center = CGPointMake(CGRectGetWidth(self.view.bounds) / 2.0,
                                  CGRectGetHeight(self.view.bounds) / 2.0);
        view;
    });
    
    // UITableView is way more performant then UICollectionView
    _tableView = ({
        CGRect rect = CGRectMake(0.f, 0.f, self.view.bounds.size.width, self.view.bounds.size.height - _infoLabel.bounds.size.height);
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
    [self.view addSubview:_infoLabel];
    [self.view addSubview:_activityIndicatorView];
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(redrawInfoLabel)];
    _displayLink.frameInterval = 4;
    [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    
    _infoLabel.text = @"Loading 1200 recent flickr photo URLs";
    [_activityIndicatorView startAnimating];
    [_recentPhotos loadPhotosWithPageCount:12 completion:^{
        _infoLabel.text = nil;
        [_activityIndicatorView stopAnimating];
        [_tableView reloadData];
    }];
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [_displayLink invalidate];
    SDFImageFetchManager *mananger = [SDFImageFetchManager sharedStressTestManager];
    [mananger setImageRequestCount:0];
    [mananger setImageRequestCancelCount:0];
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
        DFSFlickrPhoto *photo = [self _photoAtRow:indexPath.row offset:i];
        SDFImageView *imageView = [cell.imageViews objectAtIndex:i];
        imageView.image = nil;
        [imageView setImageWithURL:photo.photoURLSmall];
    }
    
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 20.f;
}


- (DFSFlickrPhoto *)_photoAtRow:(NSUInteger)row offset:(NSUInteger)offset {
    NSUInteger index = offset + row * 16;
    return [_recentPhotos.photos objectAtIndex:index];
}

#pragma mark - Redraw Info Label

- (void)redrawInfoLabel {
    if (_recentPhotos.isLoaded) {
        SDFImageFetchManager *manager = [SDFImageFetchManager sharedStressTestManager];
        NSString *text = [NSString stringWithFormat:@"Concurrent tasks: %i\nImage request count: %i\nImage request cancel count: %i", 6, manager.imageRequestCount, manager.imageRequestCancelCount];
        _infoLabel.text = text;
        
    }
}

@end

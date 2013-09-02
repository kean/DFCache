//
//  SEMenuViewController.m
//  Dwarf
//
//  Created by Alexander Grebenyuk on 8/12/13.
//  Copyright (c) 2013 Alexander Grebenyuk. All rights reserved.
//

#import "SDFMenuViewController.h"
#import "SDFImageFetchingTestViewController.h"
#import "SDFImageFetchingStressTestViewController.h"


@interface SDFMenuViewController () <UITableViewDataSource, UITableViewDelegate>

@end


@implementation SDFMenuViewController {
    NSArray *_sections;
    NSArray *_rows;
    NSArray *_controllers;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _sections =
        @[ @"DFImageFetchManager Tests" ];
        
        _rows =
        @[ @[@"Collection View Test",
             @"Stress Test"] ];
        
        _controllers =
        @[ @[ [SDFImageFetchingTestViewController class],
              [SDFImageFetchingStressTestViewController class] ] ];
    }
    return self;
}


- (void)loadView {
    [super loadView];
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    tableView.delegate = self;
    tableView.dataSource = self;
    [self.view addSubview:tableView];
    
    self.title = @"Samples";
}

#pragma mark - UITableViewDataSource & Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _sections.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_rows[section] count];
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return _sections[section];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"menuitem"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"menuitem"];
    }
    
    cell.textLabel.text = _rows[indexPath.section][indexPath.row];
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Class controllerClass = _controllers[indexPath.section][indexPath.row];
    UIViewController *controller = [controllerClass new];
    [self.navigationController pushViewController:controller animated:YES];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end

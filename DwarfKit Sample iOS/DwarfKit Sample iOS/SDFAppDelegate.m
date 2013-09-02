//
//  AppDelegate.m
//  DwarfKit Sample iOS
//
//  Created by Alexander Grebenyuk on 02.09.13.
//  Copyright (c) 2013 Alexander Grebenyuk. All rights reserved.
//

#import "SDFAppDelegate.h"
#import "SDFMenuViewController.h"


@implementation SDFAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    SDFMenuViewController *menuViewController = [SDFMenuViewController new];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:menuViewController];
    navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.window.rootViewController = navigationController;
    
    [self.window makeKeyAndVisible];
    
    return YES;
}

@end

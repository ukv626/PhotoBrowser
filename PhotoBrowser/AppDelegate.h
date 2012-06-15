//
//  AppDelegate.h
//  PhotoBrowser
//
//  Created by ukv on 4/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MWPhotoBrowser.h"

@class ViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>  {
    //
}

@property (strong, nonatomic) UIWindow *window;

//@property (strong, nonatomic) UIViewController *viewController;
@property (strong, nonatomic) UITabBarController *tabBarController;

@end

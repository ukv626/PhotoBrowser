//
//  AppDelegate.h
//  PhotoBrowser
//
//  Created by ukv on 4/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Browser.h"

@class ViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate, BrowserDelegate> {
    NSArray *_photos;
}

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, retain) NSArray *photos;

@property (strong, nonatomic) UIViewController *viewController;

@end

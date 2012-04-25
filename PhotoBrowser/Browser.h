//
//  Browser.h
//  PhotoBrowser
//
//  Created by ukv on 4/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PhotoDelegate.h"
#import "Photo.h"

// Delegate
@class Browser;
@protocol BrowserDelegate <NSObject>

- (NSUInteger)numberOfPhotosOnPage:(Browser *)browser;
- (NSUInteger)numberOfPhotos:(Browser *)browser;
- (id<PhotoDelegate>)browser:(Browser *)browser photoAtIndex:(NSUInteger)index;
@end

@interface Browser : UIViewController <UIScrollViewDelegate>

// Properties
@property (nonatomic) BOOL displayActionButton;

// Init
- (id)initWithPhotos:(NSArray *)photosArray DEPRECATED_ATTRIBUTE;
- (id)initWithDelegate:(id<BrowserDelegate>)delagate;

// Reloads the browser and refetches data
- (void)reloadData;

// Set page that browser starts on
- (void)setInitialPageIndex:(NSUInteger)index;

@end

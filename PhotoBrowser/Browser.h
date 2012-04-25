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

@interface Browser : UIViewController <UIScrollViewDelegate> {
    NSArray *photos;
}

// Properties
@property (nonatomic, retain) NSArray *photos;
@property (nonatomic, assign) NSUInteger photosPerPage;
@property (nonatomic) BOOL displayActionButton;

// Init
- (id)initWithPhotos:(NSArray *)photosArray DEPRECATED_ATTRIBUTE;
- (id)init;

// Reloads the browser and refetches data
- (void)reloadData;
- (void)reload:(NSUInteger) photosPerPage imageIndex:(NSUInteger)imageIndex;

// Set page that browser starts on
- (void)setInitialPageIndex:(NSUInteger)index;

@end

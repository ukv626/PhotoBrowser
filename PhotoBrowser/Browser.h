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

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

@interface Browser : UIViewController <UIScrollViewDelegate, UIActionSheetDelegate> {
    
}

// Properties
@property (nonatomic, retain) NSArray *photos;
@property (nonatomic, assign) NSUInteger photosPerPage;
@property (nonatomic) BOOL displayActionButton;

// Init
- (id)initWithPhotos:(NSArray *)photosArray photosPerPage:(NSUInteger)photosPerPage;
- (id)init;

// Reloads the browser and refetches data
- (void)reloadData;
- (void)reload:(NSUInteger) photosPerPage imageIndex:(NSUInteger)imageIndex;

// Set page that browser starts on
- (void)setInitialPageIndex:(NSUInteger)index;

@end

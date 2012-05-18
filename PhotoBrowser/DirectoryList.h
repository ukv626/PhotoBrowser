//
//  DirectoryList.h
//  PhotoBrowser
//
//  Created by ukv on 5/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BaseLs;
#import "LoadingDelegate.h"

@interface DirectoryList : UITableViewController <NSStreamDelegate, LoadingDelegate, UISearchBarDelegate>

// Init
- (id)initWithDriver:(BaseLs *)driver;

//
- (void)handleLoadingDidEndNotification:(id)sender;

@end

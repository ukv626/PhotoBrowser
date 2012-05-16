//
//  DirectoryList.h
//  PhotoBrowser
//
//  Created by ukv on 5/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "FtpLs.h"
#import "LoadingDelegate.h"

@interface DirectoryList : UITableViewController <NSStreamDelegate, LoadingDelegate, UISearchBarDelegate>

// Init
- (id)initWithDriver:(FtpLs *)driver;

//
- (void)handleLoadingDidEndNotification;

@end

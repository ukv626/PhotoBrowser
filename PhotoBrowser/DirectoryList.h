//
//  DirectoryList.h
//  PhotoBrowser
//
//  Created by ukv on 5/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BaseDriver;
#import "LoadingDelegate.h"

@interface DirectoryList : UITableViewController <LoadingDelegate, UISearchBarDelegate, UIActionSheetDelegate,
                                    UIDocumentInteractionControllerDelegate,UIAlertViewDelegate>

// Init
- (id)initWithDriver:(BaseDriver *)driver;

//
- (void)handleLoadingDidEndNotification:(id)sender;
- (void)handleErrorNotification:(id)sender;

- (void)handleDirectoryLoadingDidEndNotification;

@end

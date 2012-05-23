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

@interface DirectoryList : UITableViewController <LoadingDelegate, UISearchBarDelegate, 
                                    UIDocumentInteractionControllerDelegate,UIAlertViewDelegate>

// Init
- (id)initWithDriver:(BaseLs *)driver;

//
- (void)handleLoadingDidEndNotification:(id)sender;
- (void)handleErrorNotification:(id)sender;

@end

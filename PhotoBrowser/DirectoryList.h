//
//  DirectoryList.h
//  PhotoBrowser
//
//  Created by ukv on 5/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BaseDriver;
@class Downloads;
#import "UIPullToReloadTableViewController.h"
#import "LoadingDelegate.h"
#import "MWPhotoBrowser.h"

@interface DirectoryList : UIPullToReloadTableViewController <LoadingDelegate, MWPhotoBrowserDelegate, UISearchBarDelegate, UIActionSheetDelegate, UIDocumentInteractionControllerDelegate,UIAlertViewDelegate> {
    
    NSMutableArray *_photos;
    Downloads *_downloads;
    
    NSMutableArray *_dirList;
}

@property (nonatomic, assign) Downloads *downloads;

// Init
- (id)initWithDriver:(BaseDriver *)driver;

//
- (void)driver:(BaseDriver *)driver handleLoadingProgressNotification:(id)object;
- (void)driver:(BaseDriver *)driver handleAbortedNotification:(id)object;
- (void)driver:(BaseDriver *)driver handleErrorNotification:(id)object;
- (void)driver:(BaseDriver *)driver handleLoadingDidEndNotification:(id)object;
@end

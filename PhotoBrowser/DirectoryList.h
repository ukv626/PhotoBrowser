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
#import "LoadingDelegate.h"
#import "MWPhotoBrowser.h"

@interface DirectoryList : UITableViewController <LoadingDelegate, MWPhotoBrowserDelegate, UISearchBarDelegate, UIActionSheetDelegate, UIDocumentInteractionControllerDelegate,UIAlertViewDelegate> {
    
    NSMutableArray *_photos;
    Downloads *_downloads;
}

@property (nonatomic, assign) Downloads *downloads;

// Init
- (id)initWithDriver:(BaseDriver *)driver;

//
- (void)handleLoadingProgressNotification:(id)sender;
- (void)handleAbortedNotification:(id)sender;
- (void)handleErrorNotification:(id)sender;
- (void)handleLoadingDidEndNotification:(id)sender;
@end

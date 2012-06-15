//
//  Downloads.h
//  PhotoBrowser
//
//  Created by ukv on 6/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LoadingDelegate.h"
@class BaseDriver;

@interface Downloads : UITableViewController <LoadingDelegate> {
    BaseDriver *_driver;
    NSMutableArray *_files;
    
    BOOL _isLoadingInProgress;
    BOOL _isDirty;
}

@property (nonatomic, retain) BaseDriver *driver;
@property (nonatomic, readonly) BOOL isLoadingInProgress;

- (void)addFile:(NSString *)filename;
- (void)refreshBadge;

@end

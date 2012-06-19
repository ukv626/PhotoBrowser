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
@class EntryLs;

@interface Downloads : UITableViewController <LoadingDelegate> {
    BaseDriver *_driver;
    NSMutableArray *_entries;
    
    // ProgressView 
    UIProgressView *_progressView;
    
    unsigned long long _totalBytesToReceive;
    unsigned long long _totalBytesReceived;
    unsigned long long _bytesReceived;
    
    BOOL _isLoadingInProgress;
    BOOL _isDirty;
}

@property (nonatomic, retain) BaseDriver *driver;
@property (nonatomic, readonly) BOOL isLoadingInProgress;

- (void)addEntry:(EntryLs *)entry;
- (void)refreshBadge;

@end

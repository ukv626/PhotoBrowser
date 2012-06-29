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
    
    enum State {
        WAITING = 0,
        LOADING,
        PAUSED
    };
    
    NSUInteger _state;
    BOOL _isDirty;
}

@property (nonatomic, retain) BaseDriver *driver;

- (void)addEntry:(EntryLs *)entry;
- (void)refreshBadge;

@end

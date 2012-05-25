//
//  DirectoryDownloader.m
//  PhotoBrowser
//
//  Created by ukv on 5/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DirectoryDownloader.h"
#import "BaseLs.h"
#import "EntryLs.h"
#import "BaseDownloader.h"
#import "FtpLs.h"

@interface DirectoryDownloader() {
    id<LoadingDelegate> _delegate;
    
    BaseLs *_driver;
    NSMutableArray *_fileDrivers;
    NSMutableArray *_newdirDrivers;

    double _totalFilesSize;
    double _downloadedFilesSize;
}
@end

@implementation DirectoryDownloader

@synthesize delegate = _delegate;

- (id)initWithDriver:(BaseLs *)driver {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    if((self = [super init])) {
        // Custom initialization
        _driver = [driver retain];
        
        _fileDrivers = [[NSMutableArray alloc] init];
        _newdirDrivers = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [_driver release];
    [_fileDrivers release];
    [_newdirDrivers release];
    
    [super dealloc];
}

- (void)handleErrorNotification:(id)sender {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, sender);
}

- (void)handleLoadingProgressNotification:(double)value {
    // Notification from FtpDownloader
    _downloadedFilesSize += value / (1024.0 * 1024.0);
 
    // Notificate DirectoryList
    if ([_delegate respondsToSelector:@selector(handleLoadingProgressNotification:)]) {
        [_delegate handleLoadingProgressNotification:_downloadedFilesSize / _totalFilesSize];
    }
}

- (void)handleLoadingDidEndNotification:(id)sender {
    if([[sender class] isSubclassOfClass:[BaseLs class]]) {
        // Notification from BasLs
        // get file from this directory
        [self addFileDrivers:sender];
        [_newdirDrivers removeObject:sender];
        
        // просмотрены все директории - начинаем скачивание
        if (![_newdirDrivers count]) {
            [self downloadAllFiles];
        }
    } else if ([[sender class] isSubclassOfClass:[BaseDownloader class]]) {
        [_fileDrivers removeObject:sender];
    
        // All files downloaded - Notificate DirectoryList
        if (![_fileDrivers count]) {
            if([_delegate respondsToSelector:@selector(handleLoadingDidEndNotification:)]) {
                [_delegate handleLoadingDidEndNotification:self];
            }
        }
    } }

- (void)downloadAllFiles {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    for (BaseDownloader *driver in _fileDrivers) {
        [driver startReceive];
    }
}

- (void)addFileDrivers:(BaseLs *)driverLs {
    for (EntryLs *entry in driverLs.listEntries) {
        NSString *entryURL = [[driverLs.url absoluteString] stringByAppendingString:[[entry text] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        if([entry isDir]) {
            BaseLs *driver = [_driver createLsDriverWithURL:[NSURL URLWithString:[entryURL stringByAppendingString:@"/"]]];
            driver.delegate = self;
            [_newdirDrivers addObject:driver];
            [driver createDirectory];
            [driver startReceive];
        } else {
            BaseDownloader *driver = [_driver createDownloaderDriverWithURL:[NSURL URLWithString:entryURL]];
            driver.delegate = self;
            [_fileDrivers addObject:driver];
            
            _totalFilesSize += [entry size] / (1024.0 * 1024.0);
        }
    }
}
                  


- (void)startReceive {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    _downloadedFilesSize = 0.0;
    _totalFilesSize = 0.0;
    
    [self addFileDrivers:_driver];
    
    if ([_newdirDrivers count] == 0) {
        [self downloadAllFiles];
    }
}

@end

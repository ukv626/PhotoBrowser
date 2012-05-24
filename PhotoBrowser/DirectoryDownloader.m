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
#import "FtpDownloader.h"

@interface DirectoryDownloader() {
    id<LoadingDelegate> _delegate;
    
    BaseLs *_driver;
    NSMutableArray *_fileDrivers;
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
    }
    return self;
}

- (void)dealloc {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [_driver release];
    [_fileDrivers release];
    
    [super dealloc];
}

- (void)handleErrorNotification:(id)sender {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, sender);
}

- (void)handleLoadingDidEndNotification:(id)sender {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    [_fileDrivers removeObject:sender];
    
    // Notificate DirectoryList about all files downloaded
    if ([_fileDrivers count] == 0) {
        if([_delegate respondsToSelector:@selector(handleLoadingDidEndNotification:)]) {
            [_delegate handleLoadingDidEndNotification:self];
        }
    }
}


- (void)startReceive {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    for (EntryLs *entry in _driver.listEntries) {
        if(![entry isDir]) {
            NSString *filename = [entry text];
            NSString *fileURL = [[_driver.url absoluteString] stringByAppendingString:[filename stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            
            FtpDownloader *driver = [[FtpDownloader alloc] initWithURL:[NSURL URLWithString:fileURL]];
            driver.username = _driver.username;
            driver.password = _driver.password;
            driver.delegate = self;
            driver.delegateProgress = _delegate;
            [_fileDrivers addObject:driver];
            [driver startReceive];
            [driver release];
        }
    }
}

@end

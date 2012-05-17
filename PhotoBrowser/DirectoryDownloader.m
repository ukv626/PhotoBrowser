//
//  DirectoryDownloader.m
//  PhotoBrowser
//
//  Created by ukv on 5/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DirectoryDownloader.h"
#import "FtpLs.h"
#import "EntryLs.h"
#import "FtpDownloader.h"

@interface DirectoryDownloader() {
    id<LoadingDelegate> _delegate;
    
    FtpLs *_driver;
    NSMutableArray *_files;
    NSUInteger _downloaded;
}
@end

@implementation DirectoryDownloader

@synthesize delegate = _delegate;

- (id)initWithDriver:(FtpLs *)driver {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    if((self = [super init])) {
        // Custom initialization
        _driver = [driver retain];
        
        _files = [[NSMutableArray alloc] init];
        _downloaded = 0;
    }
    return self;
}

- (void)dealloc {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [_driver release];
    [_files release];
    
    [super dealloc];
}

- (void)handleLoadingDidEndNotification:(id)sender {
    NSLog(@"%s [%d/%d]", __PRETTY_FUNCTION__, _downloaded, [_files count]);
    ++_downloaded;
    if([_delegate respondsToSelector:@selector(handleLoadingDidEndNotification:)]) {
        if (_downloaded == [_files count]) {
            // Notificate DirectoryList about all files downloaded
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
            [_files addObject:driver];
            [driver startReceive];
            [driver release];
        }
    }
}

@end

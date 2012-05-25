//
//  BaseDownloader.m
//  PhotoBrowser
//
//  Created by ukv on 5/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BaseDownloader.h"

@interface BaseDownloader() {
    NSURL *_url;
    NSString *_username;
    NSString *_password;
    
    id<LoadingDelegate> _delegate;
    
    NSInputStream *_networkStream;
    NSOutputStream *_fileStream;
    
    NSUInteger _totalFileSize;
    NSUInteger _downloadedFileSize;
}

@end

@implementation BaseDownloader

@synthesize url = _url;
@synthesize username = _username;
@synthesize password = _password;

@synthesize delegate = _delegate;

@synthesize fileStream = _fileStream;
@synthesize networkStream = _networkStream;

@synthesize totalFileSize = _totalFileSize;
@synthesize downloadedFileSize = _downloadedFileSize;

- (id)initWithURL:(NSURL *)url {
    if((self = [super init])) {
        self.url = url;
        
        _totalFileSize = 0;
        _downloadedFileSize = 0;
    }
    
    return self;
}

- (void)dealloc {
    [self.username release];
    [self.password release];
    
    [self.fileStream release];
    [self.networkStream release];
    
    [super dealloc];
}

- (BOOL)isReceiving {
    return (self.networkStream != nil);
}

- (NSString *)pathToDownload {
    NSString *path = [NSString stringWithFormat:@"%@/%@", _url.host,_url.path];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    return [[paths objectAtIndex:0] stringByAppendingPathComponent:path];
}


- (void)startReceive {
    //
}

@end

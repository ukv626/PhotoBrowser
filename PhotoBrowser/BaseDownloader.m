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
    id<LoadingDelegate> _delegateProgress;
    
    NSInputStream *_networkStream;
    NSOutputStream *_fileStream;
}

@end

@implementation BaseDownloader

@synthesize url = _url;
@synthesize username = _username;
@synthesize password = _password;

@synthesize delegate = _delegate;
@synthesize delegateProgress = _delegateProgress;

@synthesize fileStream = _fileStream;
@synthesize networkStream = _networkStream;

- (id)initWithURL:(NSURL *)url {
    if((self = [super init])) {
        self.url = url;
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

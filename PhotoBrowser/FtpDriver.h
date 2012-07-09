//
//  FtpDriver.h
//  PhotoBrowser
//
//  Created by ukv on 6/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BaseDriver.h"

@interface FtpDriver : BaseDriver {
    NSNumber *_port;
    BOOL _passiveMode;

}

@property (nonatomic, retain) NSNumber *port;
@property (nonatomic, assign) BOOL passiveMode;


- (id)initWithURL:(NSURL *)url;
- (id)clone;

- (BOOL)isDownloadable;

- (BOOL)connect;
- (void)directoryList;
- (void)downloadFile:(NSString *)filename;
- (void)downloadFileAsync:(NSString *)filename;

- (NSNumber *)directorySize;

- (void)abort;


@end

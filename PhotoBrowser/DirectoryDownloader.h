//
//  DirectoryDownloader.h
//  PhotoBrowser
//
//  Created by ukv on 5/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LoadingDelegate.h"

@class FtpLs;

@interface DirectoryDownloader : NSObject<LoadingDelegate>

@property (assign) id<LoadingDelegate> delegate;

// Init
- (id)initWithDriver:(FtpLs *)driver;

//
- (void)handleLoadingDidEndNotification:(id)sender;

- (void)startReceive;

@end

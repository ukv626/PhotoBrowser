//
//  DirectoryDownloader.h
//  PhotoBrowser
//
//  Created by ukv on 5/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LoadingDelegate.h"

@class BaseLs;

@interface DirectoryDownloader : NSObject<LoadingDelegate>

@property (assign) id<LoadingDelegate> delegate;

// Init
- (id)initWithDriver:(BaseLs *)driver;

//
- (void)handleLoadingDidEndNotification:(id)sender;
- (void)handleErrorNotification:(id)sender;

- (void)startReceive;

@end

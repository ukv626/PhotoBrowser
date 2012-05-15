//
//  FtpDownloader.h
//  PhotoBrowser
//
//  Created by ukv on 5/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "BaseLs.h"

@protocol LoadingDelegate;

@interface FtpDownloader : BaseLs <NSStreamDelegate>

@property (assign) id<LoadingDelegate> delegate;

- (id)initWithURL:(NSURL *)url;

//- (id)copyWithZone:(NSZone *)zone;

@end

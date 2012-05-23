//
//  FtpDownloader.h
//  PhotoBrowser
//
//  Created by ukv on 5/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "BaseDownloader.h"

@interface FtpDownloader : BaseDownloader <NSStreamDelegate>

- (void)startReceive;

@end

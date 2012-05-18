//
//  FtpLs.h
//  PhotoBrowser
//
//  Created by ukv on 5/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseLs.h"

//@class EntryLs;


@interface FtpLs : BaseLs <NSStreamDelegate>


- (id)initWithURL:(NSURL *)url;

//- (id)copyWithZone:(NSZone *)zone;
- (BOOL)isDownloadable;

- (void)startReceive;

@end

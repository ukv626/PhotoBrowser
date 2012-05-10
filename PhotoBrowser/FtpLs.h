//
//  FtpLs.h
//  PhotoBrowser
//
//  Created by ukv on 5/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define DIRLIST_LOADING_DID_END_NOTIFICATION @"DIRLIST_LOADING_DID_END_NOTIFICATION"

@interface FtpLs : NSObject <NSStreamDelegate>


@property (nonatomic, retain) NSMutableArray *listEntries;

// Init
- (id)initWithURL:(NSURL *)url;

@end

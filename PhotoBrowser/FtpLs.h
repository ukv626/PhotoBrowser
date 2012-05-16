//
//  FtpLs.h
//  PhotoBrowser
//
//  Created by ukv on 5/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseLs.h"

@class EntryLs;

@protocol LoadingDelegate;

@interface FtpLs : BaseLs <NSStreamDelegate>

@property (assign) id<LoadingDelegate> delegate;
@property (nonatomic, readonly) NSMutableArray *listEntries;

- (id)initWithURL:(NSURL *)url;
- (BOOL)isImageFile:(NSString *)filename;
//- (BOOL)isDirectory:(NSDictionary *)entry;
- (void)createDirectory:(NSString *)path;


//- (id)copyWithZone:(NSZone *)zone;

- (void)startReceive;

@end

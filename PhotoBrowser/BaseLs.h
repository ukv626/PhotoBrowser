//
//  BaseLs.h
//  PhotoBrowser
//
//  Created by ukv on 5/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol LoadingDelegate;

@interface BaseLs : NSObject

@property (nonatomic, copy) NSURL *url;
//@property (nonatomic, copy) NSString *path;
@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *password;

@property (assign) id<LoadingDelegate> delegate;
@property (nonatomic, readonly) NSMutableArray *listEntries;

- (id)initWithURL:(NSURL *)url;
//- (id)initWithPath:(NSString *)path;
//- (id)copyWithZone:(NSZone *)zone;

- (void)sortByName;

- (BOOL)isDownloadable;
- (BOOL)isImageFile:(NSString *)filename;
- (void)createDirectory:(NSString *)path;

- (void)startReceive;


@end

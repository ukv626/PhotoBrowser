//
//  BaseLs.h
//  PhotoBrowser
//
//  Created by ukv on 5/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol LoadingDelegate;
@class BaseDownloader;

@interface BaseLs : NSObject

@property (nonatomic, copy) NSURL *url;
@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *password;

@property (assign) id<LoadingDelegate> delegate;
@property (nonatomic, readonly) NSMutableArray *listEntries;

- (id)initWithURL:(NSURL *)url;

- (void)sortByName;

- (BOOL)isDownloadable;
- (NSString *)pathToDownload;
- (BOOL)fileExist:(NSString *)filePath;
- (BOOL)isImageFile:(NSString *)filename;
- (void)createDirectory;

- (BaseLs *)createLsDriverWithURL:(NSURL *)url;
- (BaseDownloader *)createDownloaderDriverWithURL:(NSURL *)url;
- (void)startReceive;


@end

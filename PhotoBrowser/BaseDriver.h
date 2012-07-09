//
//  BaseDriver.h
//  PhotoBrowser
//
//  Created by ukv on 6/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol LoadingDelegate;

@interface BaseDriver : NSObject {
        BOOL _cacheMode;
}

@property (nonatomic, retain) NSURL *url;
@property (nonatomic, retain) NSString *username;
@property (nonatomic, retain) NSString *password;

@property (assign) id<LoadingDelegate> delegate;
@property (nonatomic, readonly) NSMutableArray *listEntries;

@property (nonatomic, assign) BOOL cacheMode;

- (id)initWithURL:(NSURL *)url;
- (id)clone;

- (BOOL)isDownloadable;
- (NSString *)pathToDownload;
- (BOOL)fileExist:(NSString *)filePath;
- (BOOL)needToDownloadFile:(NSString *)filePath withModificationDate:(NSDate *)modificationDate;
- (BOOL)isImageFile:(NSString *)filename;
- (void)createDirectory:(NSString *)directory;

- (BOOL)connect;
- (BOOL)changeDir:(NSString *)relativeDirPath;
- (void)sortByName;
- (void)directoryList;
- (void)downloadFile:(NSString *)filename;
- (void)downloadFileAsync:(NSString *)filename;

- (BOOL)deleteRemoteFile:(NSString *)filename;
- (BOOL)deleteRemoteDirictory:(NSString *)dir;

- (NSNumber *)directorySize;

- (void)abort;


@end

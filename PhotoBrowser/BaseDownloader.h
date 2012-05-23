//
//  BaseDownloader.h
//  PhotoBrowser
//
//  Created by ukv on 5/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol LoadingDelegate;

@interface BaseDownloader : NSObject

@property (nonatomic, copy) NSURL *url;
@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *password;

@property (assign) id<LoadingDelegate> delegate;
@property (assign) id<LoadingDelegate> delegateProgress;

@property (nonatomic, readonly) BOOL isReceiving;
@property (nonatomic, retain) NSInputStream *networkStream;
@property (nonatomic, retain) NSOutputStream *fileStream;

- (id)initWithURL:(NSURL *)url;

- (NSString *)pathToDownload;
- (void)startReceive;

@end

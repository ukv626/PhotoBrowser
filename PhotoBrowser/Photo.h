//
//  Image.h
//  PhotoBrowser
//
//  Created by ukv on 4/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PhotoDelegate.h"
#import "LoadingDelegate.h"
#import "FtpDownloader.h"

@interface Photo : NSObject <PhotoDelegate, LoadingDelegate >

@property (nonatomic, retain) FtpDownloader* driver;
@property (nonatomic, copy) NSString *photoPath;
@property (nonatomic, assign) NSUInteger photoNumber;
@property (nonatomic, copy) NSString *caption;

// Class
+ (Photo *)photoWithImage:(UIImage *)image;
+ (Photo *)photoWithFilePath:(NSString *)path;
//+ (Photo *)photoWithURL:(NSURL *)url;

// Init
- (id)initWithImage:(UIImage *)image;
- (id)initWithFilePath:(NSString *)path;
//- (id)initWithURL:(NSURL *)url;
- (id)initWithDriver:(FtpDownloader *)driver;

//
- (void)handleLoadingDidEndNotification;

@end

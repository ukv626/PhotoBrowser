//
//  Image.h
//  PhotoBrowser
//
//  Created by ukv on 4/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PhotoDelegate.h"


@interface Photo : NSObject <PhotoDelegate, NSStreamDelegate>

@property (nonatomic, copy) NSString *photoPath;
@property (nonatomic, assign) NSUInteger photoNumber;
@property (nonatomic, retain) NSString *caption;
@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *password;

// Class
+ (Photo *)photoWithImage:(UIImage *)image;
+ (Photo *)photoWithFilePath:(NSString *)path;
+ (Photo *)photoWithURL:(NSURL *)url;

// Init
- (id)initWithImage:(UIImage *)image;
- (id)initWithFilePath:(NSString *)path;
- (id)initWithURL:(NSURL *)url;

@end

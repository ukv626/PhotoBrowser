//
//  MWPhoto.h
//  MWPhotoBrowser
//
//  Created by Michael Waterfall on 17/10/2010.
//  Copyright 2010 d3i. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MWPhotoProtocol.h"
#import "BaseDriver.h"
#import "LoadingDelegate.h"

// This class models a photo/image and it's caption
// If you want to handle photos, caching, decompression
// yourself then you can simply ensure your custom data model
// conforms to MWPhotoProtocol

@interface MWPhoto : NSObject <MWPhoto, LoadingDelegate>

@property (nonatomic, retain) BaseDriver* driver;
@property (nonatomic, copy) NSString *photoPath;
@property (nonatomic, copy) NSString *caption;

// Class
+ (MWPhoto *)photoWithImage:(UIImage *)image;
+ (MWPhoto *)photoWithFilePath:(NSString *)path;
+ (MWPhoto *)photoWithURL:(NSURL *)url;

// Init
- (id)initWithImage:(UIImage *)image;
- (id)initWithFilePath:(NSString *)path;
- (id)initWithURL:(NSURL *)url;
- (id)initWithDriver:(BaseDriver *)driver PhotoPath:(NSString *)photoPath;

//
//- (void)handleLoadingDidEndNotification:(id)sender;
//- (void)handleErrorNotification:(id)sender;

@end

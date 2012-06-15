//
//  MWPhoto.m
//  MWPhotoBrowser
//
//  Created by Michael Waterfall on 17/10/2010.
//  Copyright 2010 d3i. All rights reserved.
//

#import "MWPhoto.h"
#import "MWPhotoBrowser.h"
#import "LoadingDelegate.h"

// Private
@interface MWPhoto () {
    id<LoadingDelegate> _delegate;
    BaseDriver *_driver;

    // Image Sources
    NSString *_photoPath;
    NSURL *_photoURL;

    // Image
    UIImage *_underlyingImage;

    // Other
    NSString *_caption;
    BOOL _loadingInProgress;
        
}

// Properties
@property (nonatomic, retain) UIImage *underlyingImage;

// Methods
- (void)imageDidFinishLoadingSoDecompress;
- (void)imageLoadingComplete;

@end

// MWPhoto
@implementation MWPhoto

// Properties
@synthesize underlyingImage = _underlyingImage, caption = _caption;
@synthesize driver = _driver;
@synthesize photoPath = _photoPath;

#pragma mark Class Methods

+ (MWPhoto *)photoWithImage:(UIImage *)image {
	return [[[MWPhoto alloc] initWithImage:image] autorelease];
}

+ (MWPhoto *)photoWithFilePath:(NSString *)path {
	return [[[MWPhoto alloc] initWithFilePath:path] autorelease];
}

+ (MWPhoto *)photoWithURL:(NSURL *)url {
	return [[[MWPhoto alloc] initWithURL:url] autorelease];
}

#pragma mark NSObject

- (id)initWithImage:(UIImage *)image {
	if ((self = [super init])) {
		self.underlyingImage = image;
	}
	return self;
}

- (id)initWithFilePath:(NSString *)path {
	if ((self = [super init])) {
		_photoPath = [path copy];
	}
	return self;
}

- (id)initWithURL:(NSURL *)url {
	if ((self = [super init])) {
		_photoURL = [url copy];
	}
	return self;
}

- (id)initWithDriver:(BaseDriver *)driver PhotoPath:(NSString *)photoPath {
    if ((self = [super init])) {
        self.driver = driver;
        self.photoPath = photoPath;
    }
    
    return self;
}

- (void)dealloc {
    [_caption release];
    [_driver release];
	[_photoPath release];
	[_photoURL release];
	[_underlyingImage release];
	[super dealloc];
}

#pragma mark MWPhoto Protocol Methods

- (UIImage *)underlyingImage {
    return _underlyingImage;
}

- (void)loadUnderlyingImageAndNotify {
    NSAssert([[NSThread currentThread] isMainThread], @"This method must be called on the main thread.");
    _loadingInProgress = YES;
    if (self.underlyingImage) {
        // Image already loaded
        [self imageLoadingComplete];
    } else {
        if ([_driver fileExist:_photoPath]) {
            // Load async from file
            [self performSelectorInBackground:@selector(loadImageFromFileAsync) withObject:nil];
        } else if (_driver.url) {
            // Download file async
            BaseDriver *downloadDriver = [_driver clone];
            downloadDriver.delegate = self;
            [downloadDriver downloadFile:[_photoPath lastPathComponent]];
        } else {
            // Failed - no source
            self.underlyingImage = nil;
            [self imageLoadingComplete];
        }
    }
}

// Release if we can get it again from path or url
- (void)unloadUnderlyingImage {
    _loadingInProgress = NO;
	if (self.underlyingImage && _photoPath) {
		self.underlyingImage = nil;
	}
}

#pragma mark - Async Loading

// Called in background
// Load image in background from local file
- (void)loadImageFromFileAsync {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    @try {
        NSError *error = nil;
        NSLog(@"%s [%@]", __PRETTY_FUNCTION__, _photoPath);
        NSData *data = [NSData dataWithContentsOfFile:_photoPath options:NSDataReadingUncached error:&error];
        if (!error) {
            self.underlyingImage = [[[UIImage alloc] initWithData:data] autorelease];
        } else {
            self.underlyingImage = nil;
            MWLog(@"Photo from file error: %@", error);
        }
    } @catch (NSException *exception) {
    } @finally {
        [self performSelectorOnMainThread:@selector(imageDidFinishLoadingSoDecompress) withObject:nil waitUntilDone:NO];
        [pool drain];
    }
}




// Called on main
- (void)imageDidFinishLoadingSoDecompress {
    NSAssert([[NSThread currentThread] isMainThread], @"This method must be called on the main thread.");
    if (self.underlyingImage) {
        // Decode image async to avoid lagging when UIKit lazy loads
    } else {
        // Failed
        
    }
    
    [self imageLoadingComplete];
}

- (void)imageLoadingComplete {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSAssert([[NSThread currentThread] isMainThread], @"This method must be called on the main thread.");
    // Complete so notify
    _loadingInProgress = NO;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:MWPHOTO_LOADING_DID_END_NOTIFICATION object:self];
}


#pragma mark - Loading Delegate

- (void)handleLoadingDidEndNotification:(id)sender {
    [self performSelectorInBackground:@selector(loadImageFromFileAsync) withObject:nil]; 
}

- (void)handleErrorNotification:(id)sender {
    self.underlyingImage = nil;
    [self imageLoadingComplete]; 
}

- (void)handleLoadingProgressNotification:(id)sender {
    //
}

- (void)handleAbortedNotification:(id)sender {
    //
}


/*
#pragma mark - SDWebImage Delegate

// Called on main
- (void)webImageManager:(SDWebImageManager *)imageManager didFinishWithImage:(UIImage *)image {
    self.underlyingImage = image;
    [self imageDidFinishLoadingSoDecompress];
}

// Called on main
- (void)webImageManager:(SDWebImageManager *)imageManager didFailWithError:(NSError *)error {
    self.underlyingImage = nil;
    MWLog(@"SDWebImage failed to download image: %@", error);
    [self imageDidFinishLoadingSoDecompress];
}

// Called on main
- (void)imageDecoder:(SDWebImageDecoder *)decoder didFinishDecodingImage:(UIImage *)image userInfo:(NSDictionary *)userInfo {
    // Finished compression so we're complete
    self.underlyingImage = image;
    [self imageLoadingComplete];
}
 */

@end

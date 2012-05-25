//
//  Image.m
//  PhotoBrowser
//
//  Created by ukv on 4/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Photo.h"
#import "Browser.h"
#import <CFNetwork/CFNetwork.h>

// Private
@interface Photo() {
    id<LoadingDelegate> _delegate;
    
    BaseDownloader *_driver;
    
    // Image sources
    NSUInteger _photoNumber;
    NSString *_photoPath;
    
    // Image
    UIImage *_underlyingImage;
    
    // Other
    NSString *_caption;
    BOOL _loadingProgress;
}

// Properties
@property (nonatomic, retain) UIImage *underlyingImage;

// Methods
- (void)imageDidFinishLoadingSoDecompress;
- (void)imageLoadingComplete;
@end

@implementation Photo

@synthesize delegate = _delegate;
@synthesize driver = _driver;
@synthesize underlyingImage = _underlyingImage, caption = _caption;
@synthesize photoNumber = _photoNumber;
//@synthesize photoURL = _photoURL;
@synthesize photoPath = _photoPath;

#pragma mark Class Methods

+ (Photo *)photoWithImage:(UIImage *)image {
    return [[[Photo alloc] initWithImage:image] autorelease];
}

+ (Photo *)photoWithFilePath:(NSString *)path {
    return [[[Photo alloc] initWithFilePath:path] autorelease];
}

#pragma mark NSObject

- (id)initWithImage:(UIImage *)image {
    if((self = [super init])) {
        self.underlyingImage = image;
    }
    return self;
}

- (id)initWithFilePath:(NSString *)path {
    if ((self = [super init])) {
        self.photoPath = path;
    }
    return  self;
}

- (id)initWithDriver:(BaseDownloader *)driver:(NSString *)photoPath {
//    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    if((self = [super init])) {
        // Custom initialization
        self.driver = driver; //[driver retain];
        self.driver.delegate = self;
        self.photoPath = photoPath;
    }
    return self;
}

- (void)dealloc {
//    NSLog(@"%s [%@]", __PRETTY_FUNCTION__, [self.photoPath lastPathComponent]);
    [_driver release];
    [_photoPath release];
    [_underlyingImage release];
    
    [super dealloc];
}


#pragma  mark Photo Protocol Methods

- (UIImage *)underlyingImage {
    return _underlyingImage;
}

- (BOOL)fileExist {
    BOOL result = NO;
    
    if([[NSFileManager defaultManager] fileExistsAtPath:self.photoPath]) {
        result = YES;
    }
    
    return result;
}

- (void)handleErrorNotification:(id)sender {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, sender);
}

- (void)handleLoadingDidEndNotification:(id)sender {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self loadImageFromFileAsync];
}

- (void)loadUnderlyingImageAndNotify {
    NSAssert([[NSThread currentThread] isMainThread], @"This method must be called on the main thread.");
    
    if(_loadingProgress == YES)
        return;
    
    _loadingProgress = YES;
    if(self.underlyingImage) {
        // Image already loaded
        [self imageLoadingComplete];
    } else {
        if([self fileExist]) {
            // Load async from file
            [self performSelectorInBackground:@selector(loadImageFromFileAsync) withObject:nil];
            //[self imageLoadingComplete];
        } else if(self.driver.url){
            [self.driver startReceive];
            
        } else {
            // Failed - no source
            self.underlyingImage = nil;
            [self imageLoadingComplete];
        }
    }        
}

// Release if we can get it again from path or url
- (void)unloadUnderlyingImage {    
    _loadingProgress = NO;
    if(self.underlyingImage && _photoPath) {
        NSLog(@"%s: %@ [%d]", __PRETTY_FUNCTION__, [_photoPath lastPathComponent], [self retainCount]);
        self.underlyingImage = nil;
    }       
}


#pragma mark - Async Loading

// Called in background
// Load image in background from local file
- (void)loadImageFromFileAsync {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    @try {
        NSError *error = nil;
        NSData *data = [NSData dataWithContentsOfFile:_photoPath options:NSDataReadingUncached error:&error];
        if(!error) {
            self.underlyingImage = [[[UIImage alloc] initWithData:data] autorelease];
            CGSize iSize = [self.underlyingImage size];
            self.caption = [NSString stringWithFormat:@"Name: %@  Size: %0.fx%0.f", [_photoPath lastPathComponent], 
                            iSize.height, iSize.width];
        } else {
            self.underlyingImage = nil;
            NSLog(@"Photo from file error: %@", error);
        }
    }
    @catch (NSException *exception) {        
    }
    @finally {
        [self performSelectorOnMainThread:@selector(imageDidFinishLoadingSoDecompress) withObject:nil waitUntilDone:NO];
        [pool drain];        
    }
}

// Called on main
- (void)imageDidFinishLoadingSoDecompress {
    NSAssert([[NSThread currentThread] isMainThread], @"This method must be called on the main thread.");
    if(self.underlyingImage) {
        // Decode image async to avoid lagging when UIKit lazy loads
        //
    } else {
        // Failed
    }
    [self imageLoadingComplete];
}

- (void)imageLoadingComplete {
    NSAssert([[NSThread currentThread] isMainThread], @"This method must be called on the main thread.");
    // Complete so notify
    _loadingProgress = NO;
  
    // Notify delegate
    if ([_delegate respondsToSelector:@selector(handleLoadingDidEndNotification:)]) {
        [_delegate handleLoadingDidEndNotification:self];
    }
//    [[NSNotificationCenter defaultCenter] postNotificationName:PHOTO_LOADING_DID_END_NOTIFICATION object:self];
}


@end

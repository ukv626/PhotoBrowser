//
//  ZoomingScrollView.m
//  PhotoBrowser
//
//  Created by ukv on 4/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ZoomingScrollView.h"
#import "Browser.h"
#import "UIImageExtras.h"


@interface Browser()
- (UIImage *)imageForPhoto:(id<PhotoDelegate>)photo;
- (void)cancelControlHiding;
- (void)hideControlsAfterDelay;
@end

@interface ZoomingScrollView() {
    NSUInteger _spacing;
}

@property (nonatomic, assign) Browser *browser;

- (void)handleSingleTap:(CGPoint)touchPoint;
- (void)handleDoubleTap:(CGPoint)touchPoint;

// other
- (CGSize)thumbnailSize;
- (void)releaseAllUnderlyingPhotos;

@end

@implementation ZoomingScrollView

@synthesize browser = _browser;
@synthesize photos = _photos;

- (id)initWithBrowser:(Browser *)browser {
    if((self = [super init])) {
        // delegate
        self.browser = browser;
        
        _imageViews = [[NSMutableArray alloc] init];
        //_photos = [[NSMutableArray alloc] init];
        
        _spacing = browser.photosPerPage  == 1 ? 0 : 5;
                
        // Image Views
        for(NSUInteger i=0; i<browser.photosPerPage; i++) {
//            NSLog(@"frame %d: %.2f, %2.f, %.2f, %.2f", i, dx, dy, thumbSize.width, thumbSize.height);
            TappingImageView *imageView = [[TappingImageView alloc] initWithFrame:CGRectZero];
            
            //_imageView.contentMode = UIViewContentModeCenter;
            imageView.backgroundColor = [UIColor darkGrayColor];
            imageView.tappingDelegate = self;
            [self addSubview:imageView];
            [_imageViews addObject:imageView];
            [imageView release];                                                            
        }        

//        // Spinner
//        _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
//        _spinner.hidesWhenStopped = YES;
//        _spinner.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
//        [self addSubview:_spinner];
        
        // Setup
        self.backgroundColor = [UIColor blackColor];
        self.delegate = self;
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;
        self.decelerationRate = UIScrollViewDecelerationRateFast;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return self;
}

- (void)dealloc {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
//    [self.browser release];
    [_imageViews release];
    [_photos release];
//    [_spinner release];
    [super dealloc];
}

- (void)releaseAllUnderlyingPhotos {
    for (id p in _photos) { 
        if (p != [NSNull null]) [p unloadUnderlyingImage]; 
    } 
    
    [_photos release];
}

- (void)setPhotos:(NSMutableArray *)photos {
    
    // Release images
    for (NSUInteger i=0; i<[_imageViews count]; i++) {
        TappingImageView *imageView = [_imageViews objectAtIndex:i];
        imageView.image = nil;
    }
    
    if (_photos != photos) {
        [_photos release];
        _photos = [photos retain];
    }

    [self displayImages];
}

- (void)prepareForReuse {   
//    for (id p in _photos) { 
//        if (p != [NSNull null]) [p unloadUnderlyingImage]; 
//    } // Release photos
    
//    [_photos release];
}

#pragma mark - Image
-(void)displayImageAtIndex:(NSUInteger)index {
    Photo *photo = [_photos objectAtIndex:index];
    UIImage *img = [[self.browser imageForPhoto:photo] imageByScalingAndCroppingForSize:CGSizeMake([self bounds].size.width, 
                                                                                                   [self bounds].size.height)];
    if(img) {
        TappingImageView *imageView = [_imageViews objectAtIndex:index];
        imageView.image = img;
//        [_spinner stopAnimating];
    } 
}


- (void)displayImages {
    CGRect bounds = [self bounds];
    
    NSLog(@"%s", __PRETTY_FUNCTION__);
    /*
    for (NSUInteger i=0; i<[_photos count]; i++) {               
        Photo *photo = [_photos objectAtIndex:i];
        
        TappingImageView *imageView = [_imageViews objectAtIndex:i];                                               
        
        if(photo && imageView.image == nil) {
            photo.photoNumber = i;
            
            // Get image from browser as it handles ordering of fetching
            UIImage *img = [[self.browser imageForPhoto:photo] imageByScalingAndCroppingForSize:CGSizeMake(bounds.size.width, bounds.size.height)];
            if(img) {
//                   NSLog(@"displayImage %d", i);
                // Hide spinner
                //[_spinner stopAnimating];
            
                // Set image
                imageView.image = img;
                imageView.hidden = NO;                           
            }
            
            // Setup image frame
            //CGRect imageViewFrame;
            //imageViewFrame.origin = CGPointZero;
            //imageViewFrame.size = img.size;
                
                
//            imageViewFrame.size.height = 240;
//            imageViewFrame.size.width = 160;
//            NSLog(@"frame: %.0f x %.0f", _imageView.frame.size.height, _imageView.frame.size.width);          
//            _imageView.frame = imageViewFrame;
//            NSLog(@"frame: %.0f x %.0f", _imageView.frame.size.height, _imageView.frame.size.width);
//            self.contentSize = imageViewFrame.size;
                
//            self.contentSize.width = 320.0;
//            self.contentSize.height = 480.0;
            
                
        } else {
            // Hide image view
//            imageView.hidden = YES;
            //[_spinner startAnimating];
        }
    }
    */
    self.contentSize = CGSizeMake(bounds.size.width, bounds.size.height);
     // Set zoom to minimum zoom
    [self setMaxMinZoomScalesForCurrentBounds];
//    [self setNeedsLayout];       
}


- (void)displayImageFailure {
//    [_spinner stopAnimating];
}


#pragma mark - Setup

- (void)setMaxMinZoomScalesForCurrentBounds {    
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    // Reset
    self.maximumZoomScale = 1;
    self.minimumZoomScale = 1;
    self.zoomScale = 1;
    self.contentSize = CGSizeMake(0, 0);    

    float dx = _spacing;
    float dy = _spacing;
    CGSize thumbSize = [self thumbnailSize];
    CGRect bounds = [self bounds];
        
    for (NSUInteger i = 0; i < self.browser.photosPerPage; i++) {                               
        TappingImageView *imageView = [_imageViews objectAtIndex:i];
        
        imageView.frame = CGRectMake(dx, dy, thumbSize.width, thumbSize.height);                                
        
        dx += thumbSize.width + _spacing;
        if(dx + thumbSize.width + _spacing > bounds.size.width) {
            dx = _spacing;
            dy += thumbSize.height + _spacing;
        }   
        
        
        if((i > [_photos count] - 1) || ([_photos count] == 0)) continue;
        // Get image
        Photo *photo = [_photos objectAtIndex:i];
                           
        if(photo) {
            photo.photoNumber = i;
            
            // Get image from browser as it handles ordering of fetching
            UIImage *img = [[self.browser imageForPhoto:photo] imageByScalingAndCroppingForSize:CGSizeMake(bounds.size.width, bounds.size.height)];
            if(img) {
                // Hide spinner
//                [_spinner stopAnimating];
                
                // Set image
                imageView.image = img;
                imageView.hidden = NO;                           
            } else {
//                [_spinner startAnimating];
            }
        }
        

    }
    
    
    // Sizes
    CGSize boundsSize = self.bounds.size;
    CGSize imageSize = [self thumbnailSize];
    
    // Calculate Min
    CGFloat xScale = boundsSize.width / imageSize.width;
    CGFloat yScale = boundsSize.height / imageSize.height;
    CGFloat minScale = MIN(xScale, yScale);
    
    // If image is smaller than the screen then ensure we show it at min scale of 1
    if(xScale > 1 && yScale > 1)
        minScale = 1.0;
    
    // Calculate Max
    CGFloat maxScale = 2.0;
    // on high resolutions screens ...
    if([UIScreen instancesRespondToSelector:@selector(scale)])
        maxScale = maxScale / [[UIScreen mainScreen] scale];
    
    // Set
    self.maximumZoomScale = maxScale;
    self.minimumZoomScale = minScale;
    self.zoomScale = minScale;
    
    [self setNeedsLayout];
}



#pragma mark - Layout

- (void)layoutSubviews {
    // Update tap view frame
    
//    // Spinner
//    if(!_spinner.hidden)
//        _spinner.center = CGPointMake(floorf(self.bounds.size.width/2.0), floorf(self.bounds.size.height/2.0));
    
    // Super
    [super layoutSubviews];
    
 }


#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    if(self.browser.photosPerPage == 1)
        return [_imageViews objectAtIndex:0];
    else 
        return nil;
}


- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [_browser cancelControlHiding];
}


- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
    [_browser cancelControlHiding];
}


- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [_browser hideControlsAfterDelay];
}


#pragma mark - Tap Detection

- (void)handleSingleTap:(CGPoint)touchPoint {
    [_browser performSelector:@selector(toggleControls) withObject:nil afterDelay:0.2];
}

- (void)handleDoubleTap:(CGPoint)touchPoint {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    // Cancel any single tap handling
    [NSObject cancelPreviousPerformRequestsWithTarget:_browser];
    
    // Zoom
    if (self.zoomScale == self.maximumZoomScale) {
        // Zoom out
        [self setZoomScale:self.minimumZoomScale animated:YES];
    }else {
        // Zoom in
        [self zoomToRect:CGRectMake(touchPoint.x, touchPoint.y, 1, 1) animated:YES];
    }
    
    // Delay controls
    [_browser hideControlsAfterDelay];
    
}

// Image View
- (void)imageView:(UIImageView *)imageView singleTapDetected:(UITouch *)touch {
    [self handleSingleTap:[touch locationInView:imageView]];    
}

- (void)imageView:(UIImageView *)imageView doubleTapDetected:(UITouch *)touch {
    NSLog(@"doubleTapDetected");
    if(_browser.photosPerPage == 1) {
        [self handleDoubleTap:[touch locationInView:imageView]];        
    } else {
        NSUInteger selectedImage;
        for (NSUInteger i=0; i<[_imageViews count]; i++) {
            TappingImageView *iView = [_imageViews objectAtIndex:i];
            if(CGRectContainsPoint(iView.frame, [touch locationInView:self])) {
                selectedImage = i;
                break;
            }            
        }
        [_browser reload:1 imageIndex:selectedImage];        
    }        
}

- (CGSize)thumbnailSize {
    CGSize resultSize;
    CGRect bounds = [self bounds];        
    
    float rowCount = sqrt(self.browser.photosPerPage);
    
    resultSize.width = floorf((bounds.size.width - _spacing * (rowCount + 1)) / rowCount);
    resultSize.height = floorf((bounds.size.height - _spacing * (rowCount + 1)) / rowCount);
    
    return resultSize;
}


@end

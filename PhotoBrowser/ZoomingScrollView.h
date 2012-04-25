//
//  ZoomingScrollView.h
//  PhotoBrowser
//
//  Created by ukv on 4/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TappingImageView.h"
#import "PhotoDelegate.h"

@class Browser;

@interface ZoomingScrollView : UIScrollView <UIScrollViewDelegate, TappingImageViewDelegate> {
    Browser *_browser;
    NSMutableArray *_photos;
//    TappingImageView *_imageView;
    NSMutableArray *_imageViews;
}

@property (nonatomic, retain) NSMutableArray *photos;

- (id)initWithBrowser:(Browser *)browser;
- (void)displayImages;
- (void)displayImageAtIndex:(NSUInteger)index;
- (void)displayImageFailure;
- (void)setMaxMinZoomScalesForCurrentBounds;
- (void)prepareForReuse;

@end

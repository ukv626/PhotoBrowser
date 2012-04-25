//
//  TappingImageView.h
//  PhotoBrowser
//
//  Created by ukv on 4/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TappingImageViewDelegate;


@interface TappingImageView : UIImageView {
    id<TappingImageViewDelegate> tappingDelegate;
}

@property (nonatomic, assign) id<TappingImageViewDelegate> tappingDelegate;

- (void)handleSingleTap:(UITouch *)touch;
- (void)handleDoubleTap:(UITouch *)touch;
- (void)handleTrippleTap:(UITouch *)touch;
@end

@protocol TappingImageViewDelegate <NSObject>

@optional
- (void)imageView:(UIImageView *)imageView singleTapDetected:(UITouch *)touch;
- (void)imageView:(UIImageView *)imageView doubleTapDetected:(UITouch *)touch;
- (void)imageView:(UIImageView *)imageView tripleTapDetected:(UITouch *)touch;

@end

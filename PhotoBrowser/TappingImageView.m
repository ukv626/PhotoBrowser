//
//  TappingImageView.m
//  PhotoBrowser
//
//  Created by ukv on 4/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TappingImageView.h"
#import <QuartzCore/QuartzCore.h>

@implementation TappingImageView

@synthesize tappingDelegate;

- (id)initWithFrame:(CGRect)frame
{
    if((self = [super initWithFrame:frame])) {
        self.userInteractionEnabled = YES;
        // Initialization code
        
        CALayer *l = [self layer];
        [l setMasksToBounds:YES];
        [l setCornerRadius:6.0];
        
//        [l setBorderWidth:2.0];
//        [l setBorderColor:[[UIColor blackColor] CGColor]];
    }
    return self;
}


- (id)initWithImage:(UIImage *)image {
    if((self = [super initWithImage:image])) {
        self.userInteractionEnabled = YES;
    }
    return self;
}


- (id)initWithImage:(UIImage *)image highlightedImage:(UIImage *)highlightedImage {
    if((self = [super initWithImage:image highlightedImage:highlightedImage])) {
        self.userInteractionEnabled = YES;
    }
    return self;
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {    
    UITouch *touch = [touches anyObject];
    NSUInteger tapCount = touch.tapCount;
    switch (tapCount) {
        case 1:
            [self handleSingleTap:touch];            
            break;
        case 2:
            [self handleDoubleTap:touch];
            break;
        case 3:
            [self handleTrippleTap:touch];
            break;            
        default:
            break;
    }
    [[self nextResponder] touchesEnded:touches withEvent:event];
}


- (void)handleSingleTap:(UITouch *)touch {
    if([tappingDelegate respondsToSelector:@selector(imageView:singleTapDetected:)])
        [tappingDelegate imageView:self singleTapDetected:touch];
}


- (void)handleDoubleTap:(UITouch *)touch {
    if([tappingDelegate respondsToSelector:@selector(imageView:doubleTapDetected:)])
        [tappingDelegate imageView:self doubleTapDetected:touch];
}


- (void)handleTrippleTap:(UITouch *)touch {
    if([tappingDelegate respondsToSelector:@selector(imageView:tripleTapDetected:)])
        [tappingDelegate imageView:self tripleTapDetected:touch];
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end

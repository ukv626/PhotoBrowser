//
//  CaptionView.m
//  PhotoBrowser
//
//  Created by ukv on 5/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CaptionView.h"
#import "PhotoDelegate.h"

static const CGFloat labelPadding = 10;

@interface CaptionView() {
    id<PhotoDelegate> _photo;
    UILabel *_label;
}

@end

@implementation CaptionView

- (id)initWithPhoto:(id<PhotoDelegate>)photo {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    self = [super initWithFrame:CGRectMake(0, 0, 320, 33)]; //Random initial frame
    if (self) {
        // Initialization code
        _photo = [photo retain];
        
        self.opaque = NO;
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;

        _label = [[UILabel alloc] initWithFrame:CGRectMake(labelPadding, 0, 
                                                           self.bounds.size.width - labelPadding*2, 
                                                           self.bounds.size.height)];
        _label.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        _label.opaque = NO;
        _label.backgroundColor = [UIColor clearColor];
        _label.textAlignment = UITextAlignmentCenter;
        _label.lineBreakMode = UILineBreakModeWordWrap;
        _label.numberOfLines = 3;    
        _label.textColor = [UIColor whiteColor];
        _label.shadowColor = [UIColor blackColor];
        _label.shadowOffset = CGSizeMake(1.0, 1.0);
        _label.font = [UIFont systemFontOfSize:17];
        if ([_photo respondsToSelector:@selector(caption)]) {
            _label.text = [_photo caption] ? [_photo caption] : @""; //ukv       bad access
        }
        
        [self addSubview:_label];
    }
    NSLog(@"before return");
    return self;
}

- (CGSize)sizeThatFits:(CGSize)size {
    CGFloat maxHeight = 9999;
    if(_label.numberOfLines > 0) maxHeight = _label.font.leading * _label.numberOfLines;
    CGSize textSize = [ _label.text sizeWithFont:_label.font constrainedToSize:CGSizeMake(size.width - labelPadding*2, maxHeight)
                                   lineBreakMode:_label.lineBreakMode];
    return CGSizeMake(size.width, textSize.height + labelPadding * 2);
}


- (void)setupCaptionText:(NSString *)text {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    _label.text = text;
}

- (void)dealloc {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [_label release];
    [_photo release];
    
    [super dealloc];
}

@end

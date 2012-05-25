//
//  CaptionView.h
//  PhotoBrowser
//
//  Created by ukv on 5/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PhotoDelegate.h"

@interface CaptionView : UIView

// Init
- (id)initWithPhoto:(id<PhotoDelegate>)photo;

- (void)setupCaptionText:(NSString *)text;

- (CGSize)sizeThatFits:(CGSize)size;

@end

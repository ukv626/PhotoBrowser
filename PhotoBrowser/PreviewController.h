//
//  PreviewController.h
//  PhotoBrowser
//
//  Created by ukv on 7/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "KTThumbsViewController.h"
#import "KTThumbView.h"

@class MWPhotoBrowser;

@interface PreviewController : KTThumbsViewController {
    MWPhotoBrowser *_browser;
}

@property (nonatomic, assign) MWPhotoBrowser *browser;

@end

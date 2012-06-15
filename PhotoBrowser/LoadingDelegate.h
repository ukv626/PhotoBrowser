//
//  LoadingDelegate.h
//  PhotoBrowser
//
//  Created by ukv on 5/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol LoadingDelegate <NSObject>

@required
- (void)handleLoadingDidEndNotification:(id)sender;
- (void)handleErrorNotification:(id)sender;
- (void)handleLoadingProgressNotification:(id)sender;
- (void)handleAbortedNotification:(id)sender;

@end

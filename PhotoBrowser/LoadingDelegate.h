//
//  LoadingDelegate.h
//  PhotoBrowser
//
//  Created by ukv on 5/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BaseDriver;
@protocol LoadingDelegate <NSObject>

@required
- (void)driver:(BaseDriver *)driver handleLoadingDidEndNotification:(id)object;
- (void)driver:(BaseDriver *)driver handleErrorNotification:(id)object;
- (void)driver:(BaseDriver *)driver handleLoadingProgressNotification:(id)object;
- (void)driver:(BaseDriver *)driver handleAbortedNotification:(id)object;

@end

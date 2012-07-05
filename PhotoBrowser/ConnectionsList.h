//
//  ConnectionsList.h
//  PhotoBrowser
//
//  Created by ukv on 5/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Downloads;
@class Reachability;

@interface ConnectionsList : UITableViewController <UIGestureRecognizerDelegate> {
    BOOL _isDirty;
    
    Downloads *_downloads;
    Reachability *_internetReach;
}

- (id)initWithDownloads:(Downloads *)downloads;

- (NSString *)connectionsFilePath;
- (void)needToRefresh;

@end

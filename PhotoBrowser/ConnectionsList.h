//
//  ConnectionsList.h
//  PhotoBrowser
//
//  Created by ukv on 5/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Downloads;

@interface ConnectionsList : UITableViewController {
    BOOL _isDirty;
    
    Downloads *_downloads;
}

- (id)initWithDownloads:(Downloads *)downloads;

- (NSString *)connectionsFilePath;
- (void)needToRefresh;

@end

//
//  DirectoryList.h
//  PhotoBrowser
//
//  Created by ukv on 5/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BaseLs;

@interface DirectoryList : UITableViewController <NSStreamDelegate>

// Init
- (id)initWithDriver:(BaseLs *)driver;

@end

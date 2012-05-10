//
//  DirectoryList.h
//  PhotoBrowser
//
//  Created by ukv on 5/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DirectoryList : UITableViewController <NSStreamDelegate>

// Init
- (id)initWithURL:(NSURL *)url;

@end

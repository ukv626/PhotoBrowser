//
//  FtpLs.h
//  PhotoBrowser
//
//  Created by ukv on 5/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FtpLs : NSObject <NSStreamDelegate> {
    NSURL *_url;
    NSInputStream *_networkStream;
    NSMutableData *_listData;
    NSMutableArray *_listEntries;
}

@property (nonatomic, retain) NSMutableArray *listEntries;

// Init
- (id)initWithURL:(NSURL *)url;

@end

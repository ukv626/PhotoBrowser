//
//  BaseLs.h
//  PhotoBrowser
//
//  Created by ukv on 5/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define DIRLIST_LOADING_DID_END_NOTIFICATION @"DIRLIST_LOADING_DID_END_NOTIFICATION"

@interface BaseLs : NSObject {
    
}

@property (nonatomic, retain) NSURL *url;
@property (nonatomic, readonly) NSMutableArray *listEntries;
@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *password;

- (id)initWithURL:(NSURL *)url;

- (void)startReceive;

- (BOOL)isImageFile:(NSDictionary *)entry;
- (BOOL)isDirectory:(NSDictionary *)entry;
- (void)createDirectory:(NSString *)path;

@end

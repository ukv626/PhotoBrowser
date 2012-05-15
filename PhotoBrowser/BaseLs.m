//
//  BaseLs.m
//  PhotoBrowser
//
//  Created by ukv on 5/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BaseLs.h"


@interface BaseLs() {
    NSURL *_url;
    NSString *_username;
    NSString *_password;
}

@end

@implementation BaseLs


@synthesize url = _url;
@synthesize username = _username;
@synthesize password = _password;


- (id)initWithURL:(NSURL *)url {
    if((self = [super init])) {
        self.url = url;
    }
    
    return self;
}

- (void)dealloc {
    [self.username release];
    [self.password release];
    
    [super dealloc];
}

- (void)startReceive {
    //
}

/*
- (id)copyWithZone:(NSZone *)zone {
//    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    BaseLs *newCopy = [[[self class] allocWithZone: zone] init];
    [newCopy setUrl:self.url];
    [newCopy setUsername:self.username];
    [newCopy setPassword:self.password];
    
    return newCopy;
}
*/

@end

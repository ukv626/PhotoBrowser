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
    NSMutableArray *_listEntries;
    NSString *_username;
    NSString *_password;
}

@end

@implementation BaseLs

@synthesize url = _url;
@synthesize listEntries = _listEntries;
@synthesize username = _username;
@synthesize password = _password;

- (id)initWithURL:(NSURL *)url {
    if ((self = [super init])) {
        _url = [url copy];
        _listEntries = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc {
    [_url release];
    [_listEntries release];
    
    [super dealloc];
}

- (void)startReceive {
    //
}

- (BOOL)isImageFile:(NSDictionary *)entry {
    BOOL        result = NO;
    
    assert(entry != nil);
    
    NSString *filename = [entry objectForKey:(id) kCFFTPResourceName];
    NSString *extension;    
    
    if (filename != nil) {
        extension = [filename pathExtension];
        if (extension != nil) {
            result = ([extension caseInsensitiveCompare:@"gif"] == NSOrderedSame)
            || ([extension caseInsensitiveCompare:@"png"] == NSOrderedSame)
            || ([extension caseInsensitiveCompare:@"jpg"] == NSOrderedSame)
            || ([extension caseInsensitiveCompare:@"jpeg"] == NSOrderedSame);
        }
    }
    
    return result;
}

- (BOOL)isDirectory:(NSDictionary *)entry {
    return NO;
}

- (void)createDirectory:(NSString *)path {
    //
}

@end

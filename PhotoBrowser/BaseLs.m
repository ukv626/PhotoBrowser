//
//  BaseLs.m
//  PhotoBrowser
//
//  Created by ukv on 5/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BaseLs.h"
#import "EntryLs.h"

@interface BaseLs() {
    NSURL *_url;
//    NSString *_path;
    NSString *_username;
    NSString *_password;
    
    id<LoadingDelegate> _delegate;
    
    NSMutableArray *listEntries;
}

@end

@implementation BaseLs

@synthesize url = _url;
@synthesize username = _username;
@synthesize password = _password;
@synthesize delegate = _delegate;
@synthesize listEntries = _listEntries;


- (id)initWithURL:(NSURL *)url {
    if((self = [super init])) {
        self.url = url;
//        self.path = [url absoluteString];
        _listEntries = [[NSMutableArray alloc] init];
    }
    
    return self;
}


//- (id)initWithPath:(NSString *)path {
//    if((self = [super init])) {
//        self.path = path;
//        _listEntries = [[NSMutableArray alloc] init];
//    }
//    
//    return self;
//}

- (void)dealloc {
    [self.username release];
    [self.password release];
    
    [self.listEntries release];
    
    [super dealloc];
}

- (BOOL)isDownloadable {
    return  NO;
}

- (NSString *)pathToDownload {
    NSString *result;
    if ([_url.host isEqualToString:@"localhost"]) { 
        result = [_url path];
    }
    else {
        NSString *path = [NSString stringWithFormat:@"%@/%@", _url.host,_url.path];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        result = [[paths objectAtIndex:0] stringByAppendingPathComponent:path];
    }
    NSLog(@"PATH2DOWN %@", result);
    return result;
}

- (BOOL)fileExist:(NSString *)filePath {
    BOOL result = NO;
    
    if([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        result = YES;
    }
    
    return result;
}

- (BOOL)isImageFile:(NSString *)filename {
    BOOL result = NO;
    
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

- (void)createDirectory {
    NSString *path = [self pathToDownload];
    NSError *error;
    
    //    NSLog(@"%@", path);
    if(![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        if(![[NSFileManager defaultManager] createDirectoryAtPath:path 
                                      withIntermediateDirectories:YES attributes:nil error:&error]) {
            NSLog(@"Create directory error: %@", error);
            
        }
    }
    
}

- (void)startReceive {
    //
}

- (void)sortByName {
    NSMutableArray *files = [[NSMutableArray alloc] init];
    NSMutableArray *dirs = [[NSMutableArray alloc] init];
    
    for (EntryLs *entry in self.listEntries) {
        if (entry.isDir) {
            [dirs addObject:entry];
        } else {
            [files addObject:entry];
        }
    }
    
    NSArray *sortedFiles = [files sortedArrayUsingComparator:^NSComparisonResult(EntryLs *obj1, EntryLs *obj2) {
            return [obj1.text compare:obj2.text];
        }];
    
    NSArray *sortedDirs = [dirs sortedArrayUsingComparator:^NSComparisonResult(EntryLs *obj1, EntryLs *obj2) {
            return [obj1.text compare:obj2.text];
        }];
    
    [files release];
    [dirs release];
    
    [self.listEntries removeAllObjects];
    [self.listEntries addObjectsFromArray:sortedDirs];
    [self.listEntries addObjectsFromArray:sortedFiles];
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

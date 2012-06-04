//
//  FtpDriver.m
//  PhotoBrowser
//
//  Created by ukv on 6/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FtpDriver.h"
#import "LoadingDelegate.h"
#import "EntryLs.h"

#import "CkoFtp2.h"
#import "XMLReader.h"

@interface FtpDriver() {
    CkoFtp2 *_driver;
    
    unsigned long long _totalDirectorySize;
//    NSLock *_lock;
}

- (BOOL)connect;
//- (void)_directoryList;

@end

@implementation FtpDriver

- (id)initWithURL:(NSURL *)url {
    if ((self = [super initWithURL:url])) {
        _driver = [[CkoFtp2 alloc] init];
//        _lock = [[NSLock alloc] init];
    }
    
    return self;
}

- (id)clone {
    FtpDriver *copy = [[[FtpDriver alloc] initWithURL:self.url] autorelease];
    copy.username = self.username;
    copy.password = self.password;
    return copy;
}

- (void)dealloc {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [_driver Disconnect];
    [_driver release];
    
    [super dealloc];
}

- (BOOL)changeDir:(NSString *)relativeDirPath {
    if (!_driver.IsConnected) {
        return NO;
    }

    BOOL success = [_driver ChangeRemoteDir:relativeDirPath]; 
    return success;
}

- (BOOL)isDownloadable {
    return YES;
}

- (BOOL)connect {
    BOOL success = [_driver UnlockComponent:@"qwe"];
    if (success) {
        _driver.Hostname = [self.url host];
        _driver.Username = self.username;
        _driver.Password = self.password;
    
        if((success = [_driver Connect])) {
            success = [_driver ChangeRemoteDir:[[self.url path] substringFromIndex:1]];
        }
    }
    
    return success;
}

- (void)directoryList {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self.listEntries removeAllObjects];
    
    BOOL success = YES;
    if (!_driver.IsConnected) {
        success = [self connect];
    }

    if (success) {
        int n = [_driver.NumFilesAndDirs intValue];
        if (n > 0) {
            for (int i = 0; i < n; i++) {
                NSNumber *fileNum = [NSNumber numberWithInt:i];
            
                NSString *filename = [_driver GetFilename:fileNum];
                NSNumber *fileSize = [_driver GetSize:fileNum];
                BOOL isDir = [_driver GetIsDirectory:fileNum];
                NSDate *fileModDate = [_driver GetLastModifiedTime:fileNum];
                                  
                EntryLs *entry = [[EntryLs alloc] initWithText:filename IsDirectory:isDir 
                                                          Date:fileModDate Size:[fileSize unsignedLongLongValue]];
            
                [self.listEntries addObject:entry];
                [entry release];
            }
        }
        [self sortByName];
    
        if([self.delegate respondsToSelector:@selector(handleLoadingDidEndNotification:)]) {
            [self.delegate handleLoadingDidEndNotification:self];
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(handleErrorNotification:)]) {
            [self.delegate handleErrorNotification:self];
        }
    }
}

- (void)downloadFile:(NSString *)filename {
//    [_lock lock];
    NSLog(@"BEGIN %s [%@]", __PRETTY_FUNCTION__, filename);
    
    BOOL success = YES;
    
    if (!_driver.IsConnected) {
        success = [self connect];
    }
    
    [_driver GetFile:filename localFilename:[[self pathToDownload] stringByAppendingPathComponent:filename]];
    /*
    if (success && [_driver GetFile:filename localFilename:[[self pathToDownload] stringByAppendingPathComponent:filename]]) {
        if([self.delegate respondsToSelector:@selector(handleLoadingDidEndNotification:)]) {
            [self.delegate  handleLoadingDidEndNotification:self];                                                                          
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(handleErrorNotification:)]) {
            [self.delegate handleErrorNotification:self];
        }
    }
     */
    NSLog(@"END");
//    [_lock unlock];
}

- (void)downloadDirectory {
    BOOL success = YES;
    if (!_driver.IsConnected) {
        success = [self connect];
    }
    
    if (success) {
        [_driver setDirListingCharset:@"utf-8"];
        NSString *xmlStr = [_driver DirTreeXml];
        
        NSError *parseError = nil;
        NSArray *files = [XMLReader arrayForXMLString:xmlStr error:&parseError];

        NSString *currentDir = [_driver GetCurrentRemoteDir];
        _totalDirectorySize = 0;
        for (NSString *file in files) {
            NSString *newDir = [file stringByDeletingLastPathComponent];
            if (![currentDir isEqualToString:newDir]) {
                [_driver ChangeRemoteDir:newDir];
                currentDir = newDir;
            }
            NSNumber * fileSize = [_driver GetSizeByName64:[file lastPathComponent]];
            _totalDirectorySize += [fileSize unsignedLongLongValue];
        }
        NSLog(@"TOTAL SIZE = %llu", _totalDirectorySize);
    }
    
    /*
    if(success && [_driver DownloadTree:[self pathToDownload]]) {
        if([self.delegate respondsToSelector:@selector(handleDirectoryLoadingDidEndNotification)]) {
            [self.delegate handleDirectoryLoadingDidEndNotification];
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(handleErrorNotification:)]) {
            [self.delegate handleErrorNotification:self];
        }
    }
     */
}


@end

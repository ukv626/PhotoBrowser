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
#import "UIImage+KTCategory.h"
#import "UIImage+ImmediateLoading.m"

@interface FtpDriver() {
    CkoFtp2 *_driver;
    BOOL _aborted;
    
    NSString *_originalRemoteDir;
}

@property (nonatomic, retain) NSString *originalRemoteDir;

@end

@implementation FtpDriver

@synthesize originalRemoteDir = _originalRemoteDir;
@synthesize port = _port;
@synthesize passiveMode = _passiveMode;
@synthesize encoding = _encoding;


- (id)initWithURL:(NSURL *)url {
    if ((self = [super initWithURL:url])) {
        _driver = [[CkoFtp2 alloc] init];
    }
    
    return self;
}

- (id)clone {
    FtpDriver *copy = [[[FtpDriver alloc] initWithURL:self.url] autorelease];
    copy.username = self.username;
    copy.password = self.password;
    copy.port = self.port;
    copy.passiveMode = self.passiveMode;
    copy.originalRemoteDir = self.originalRemoteDir;
    copy.encoding = self.encoding;
    return copy;
}

- (void)dealloc {
    [_driver Disconnect];
    [_driver release];
    [_originalRemoteDir release];
    
    [super dealloc];
}

- (BOOL)changeDir:(NSString *)relativeDirPath {
    if (!_driver.IsConnected) {
        return NO;
    }
    
    return [_driver ChangeRemoteDir:relativeDirPath];
}

 
- (BOOL)isDownloadable {
    return YES;
}

- (BOOL)connect {
    BOOL success = [_driver UnlockComponent:@"EVGENIFTP_ZdydGMurmTnt"];
    if (!success) {
        return NO;
    }
    
    _driver.Hostname = [self.url host];
    if (self.username.length > 0) _driver.Username = self.username;
    if (self.password.length > 0) _driver.Password = self.password;
    _driver.Port = self.port;
    _driver.Passive = self.passiveMode;
    
     if ([self.url.scheme isEqualToString:@"ftps"]) {
         _driver.AuthTls = YES;
         _driver.Ssl = NO;
     }
    
    if((success = [_driver Connect])) {
        if (self.encoding.length > 0) {
            [_driver setDirListingCharset:self.encoding];
            //[_driver setCrlfMode:[NSNumber numberWithInt:1]];
        }
        
        if (![[self.url path] isEqualToString:@"/"]) {
            success = [_driver ChangeRemoteDir:[[self.url path] substringFromIndex:1]];
        }
        self.originalRemoteDir = [_driver GetCurrentRemoteDir];
    }
    
    return success;
}

- (void)directoryList {
    BOOL success = _driver.IsConnected;
    if (!success) {
        success = [self connect];
    }

    [self.listEntries removeAllObjects];
    
    if (!success) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate driver:self handleErrorNotification:[self errorStr]];
        });
    }
    else {
        [_driver setListPattern:@"*"];
        int n = [_driver.NumFilesAndDirs intValue];
        if (n > 0) {
            for (int i = 0; i < n; i++) {
                NSNumber *fileNum = [NSNumber numberWithInt:i];
            
                NSString *filename = [_driver GetFilename:fileNum];
                if ([filename isEqualToString:@"."] ||
                    [filename isEqualToString:@".."]) {
                    continue;
                }
                
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
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate driver:self handleLoadingDidEndNotification:@"DIRECTORY_LIST_RECEIVED"];
        });
    } 
}


- (void)downloadFile:(NSString *)filename {
    [self performSelectorInBackground:@selector(_downloadFile:) withObject:filename];
}

- (void)_downloadFile:(NSString *)filename {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    @try {
        BOOL success = _driver.IsConnected;
        
        if (!success) {
            success = [self connect];
        }
        
        if (success) {
            success = [_driver GetFile:filename localFilename:[[self pathToDownload] stringByAppendingPathComponent:filename]];
            [self saveThumb:filename];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate driver:self handleLoadingDidEndNotification:filename];
            });
            
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate driver:self handleErrorNotification:[NSString stringWithFormat:@"Error: %@", filename]];
            });
        }
    }
    @catch (NSException *exception) {        
    }
    @finally {
        [pool drain];        
    }
}

- (void)downloadFileAsync:(NSString *)filepath {
    BOOL success = _driver.IsConnected;
    
    if (!success) {
        success = [self connect];
    }
    
    if (!success) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate driver:self handleErrorNotification:[self errorStr]];
        });
    }
    else {
        _aborted = NO;
        _driver.RestartNext = YES;
        
        NSString *urlPath = [self.url.path stringByReplacingOccurrencesOfString:@"//" withString:@"/"];
        NSString *relFilepath = [[self.url path] isEqualToString:@"/"] ? 
                    filepath :
        //[filepath lastPathComponent];
                    [[filepath stringByReplacingOccurrencesOfString:urlPath withString:@""] substringFromIndex:1]; 
        NSString *newRemoteDir = [_originalRemoteDir stringByAppendingPathComponent:[relFilepath stringByDeletingLastPathComponent]];
                
        [_driver ChangeRemoteDir:newRemoteDir];

        [self createDirectory:[relFilepath stringByDeletingLastPathComponent]];
        
        NSString *localFilename = [[self pathToDownload] stringByAppendingPathComponent:relFilepath];
        
        success = [_driver AsyncGetFileStart:[filepath lastPathComponent] localFilename:localFilename];
        if (success) {
            NSNumber *bytesReceived = [NSNumber numberWithInt:0];
            while (_driver.AsyncFinished != YES) {
                bytesReceived = _driver.AsyncBytesReceived64;
                [_driver SleepMs:[NSNumber numberWithInt:500]];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate driver:self handleLoadingProgressNotification:bytesReceived]; 
                });
            }
            if (!_aborted) {
                [self saveThumb:filepath];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate driver:self handleLoadingDidEndNotification:filepath]; 
                });
                
            } else {
                // remove this to DirectoryList
                //[[NSFileManager defaultManager] removeItemAtPath:localFilename error:nil];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate driver:self handleAbortedNotification:filepath]; 
                });
            }
        } 
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate driver:self handleErrorNotification:[NSString stringWithFormat:@"Error: %@", filepath]];
            });
        }
        
    } 
}


- (NSNumber *)directorySize {
    BOOL success = _driver.IsConnected;
    if (!success) {
        success = [self connect];
    }
    
    unsigned long long totalDirectorySize = 0;
    
    if (!success) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate driver:self handleErrorNotification:[self errorStr]];
//            @"DIRECTORY_SIZE_RECEIVED"
        });
    } else {
        [self.listEntries removeAllObjects];
        
//        [_driver setDirListingCharset:@"utf-8"];
        NSString *xmlStr = [_driver DirTreeXml];
        
        NSError *parseError = nil;
        NSArray *files = [XMLReader arrayForXMLString:xmlStr error:&parseError];
        
        // calculate total directory size
        NSString *currentDir = [_driver GetCurrentRemoteDir];
        NSString *originalCurrentDir = currentDir;
        
        for (NSString *filepath in files) {
            NSString *newDir = [originalCurrentDir stringByAppendingPathComponent:[filepath stringByDeletingLastPathComponent]];
            if (![currentDir isEqualToString:newDir]) {
                [_driver ChangeRemoteDir:newDir];
                currentDir = newDir;
            }
            NSNumber *fileSize = [_driver GetSizeByName64:[filepath lastPathComponent]];
            totalDirectorySize += [fileSize unsignedLongLongValue];
            
            NSDate *fileModDate = [_driver GetLastModifiedTimeByName:[filepath lastPathComponent]];
            
            EntryLs *entry = [[EntryLs alloc] initWithText:[[self.url path] stringByAppendingPathComponent:filepath] 
                                               IsDirectory:NO Date:fileModDate Size:[fileSize unsignedLongLongValue]];
            [self.listEntries addObject:entry];
            [entry release];
        }
        [self sortByName];
        
        // restore current dir
        [_driver ChangeRemoteDir:originalCurrentDir];
    }
    
    return [NSNumber numberWithUnsignedLongLong:totalDirectorySize];
}

- (BOOL)deleteRemoteFile:(NSString *)filename {
    BOOL success = _driver.IsConnected;
    
    if (!success) {
        success = [self connect];
    }
    
    if (success) {
        success = [_driver DeleteRemoteFile:filename];
    }
    
    if (!success) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate driver:self handleErrorNotification:_driver.LastErrorText];
        });
    }
    
    return success;
}

- (BOOL)deleteRemoteDirictory:(NSString *)dir {
    BOOL success = _driver.IsConnected;
    
    if (!success) {
        success = [self connect];
    }
    
    if (success) {
        success = [_driver RemoveRemoteDir:dir];
    }
    
    if (!success) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate driver:self handleErrorNotification:_driver.LastErrorText];
        });
    }
    
    return success;
}

- (void)abort {
    [_driver AsyncAbort];
    _aborted = YES;
}

- (NSString *)errorStr {
    NSString *result;
    int errorCode = [[_driver ConnectFailReason] intValue];
    switch (errorCode) {
        case 1:
            result = @"Empty hostname";
            break;
        case 2:
            result = @"DNS lookup failed";
            break;
        case 3:
            result = @"DNS timeout";
            break;
        case 4:
            result = @"Aborted by application";
            break;
        case 5:
            result = @"Internal failure";
            break;
        case 6:
            result = @"Connect Timed Out";
            break;
        case 7:
            result = @"Connect Rejected";
            break;
            // SSL
        case 100:
            result = @"Internal schannel error";
            break;
        case 101:
            result = @"Failed to create credentials";
            break;
        case 102:
            result = @"Failed to send initial message to proxy";
            break;
        case 103:
            result = @"Handshake failed";
            break;
        case 104:
            result = @"Failed to obtain remote certificate";
            break;
        case 105:
            result = @"Failed to verify server certificate";
            break;
            // FTP
        case 200:
            result = @"Connected, but failed to receive greeting from FTP server";
            break;
        case 201:
            result = @"Failed to do AUTH TLS or AUTH SSL";
            break;
            // Protocol/Component
        case 300:
            result = @"Asynch op in progress";
            break;
        case 301:
            result = @"Login failure";
            break;
        default:
            result = @"Unknow error!!";
            break;
    }
    return result;
}

- (void)saveThumb:(NSString *)filename {
    
    if (![self isImageFile:filename]) {
        return;
    }
    
    if ([filename isEqualToString:[filename lastPathComponent]]) {
        filename = [self.url.path stringByAppendingPathComponent:filename];
    }
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *filepath = [NSString stringWithFormat:@"%@/Downloads/%@/%@", [paths objectAtIndex:0], self.url.host, filename];;
    UIImage *image = [UIImage imageImmediateLoadWithContentsOfFile:filepath];
    UIImage *thumb = [image imageScaleAndCropToMaxSize:CGSizeMake(75, 75)];
    NSData *jpg = UIImageJPEGRepresentation(thumb, 0.8);
        
    NSString *thumbPath = [NSString stringWithFormat:@"%@/Thumbs/%@/%@", [paths objectAtIndex:0], self.url.host, filename];
    
    NSError *error;
    NSString *dir = [thumbPath stringByDeletingLastPathComponent];
    if(![[NSFileManager defaultManager] fileExistsAtPath:dir]) {
        if(![[NSFileManager defaultManager] createDirectoryAtPath:dir 
                                      withIntermediateDirectories:YES attributes:nil error:&error]) {
            NSLog(@"error");
        }
    }
//    NSLog(@"thumbPath=%@", thumbPath);
    
    [jpg writeToFile:thumbPath atomically:NO];
}

@end

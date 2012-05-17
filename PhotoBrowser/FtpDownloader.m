//
//  FtpDownloader.m
//  PhotoBrowser
//
//  Created by ukv on 5/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//


#import "FtpDownloader.h"
#import "Photo.h"
#import "LoadingDelegate.h"

#import <CFNetwork/CFNetwork.h>

@interface FtpDownloader () {  
    id<LoadingDelegate> _delegate;
    id<LoadingDelegate> _delegateProgress;
    NSInputStream *_networkStream;
    NSOutputStream *_fileStream;
    
//    NSUInteger _fileSize;
}
@property (nonatomic, readonly) BOOL isReceiving;
@property (nonatomic, retain) NSInputStream *networkStream;
@property (nonatomic, retain) NSOutputStream *fileStream;

@end

@implementation FtpDownloader

@synthesize delegate = _delegate;
@synthesize delegateProgress = _delegateProgress;
@synthesize fileStream = _fileStream;
@synthesize networkStream = _networkStream;

- (id)initWithURL:(NSURL *)url {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    return [super initWithURL:url];
}


- (BOOL)isReceiving {
    return (self.networkStream != nil);
}


- (void)startReceive {
    //    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSLog(@"%s: %@ [%@]", __PRETTY_FUNCTION__, self.url, self.username);
    
//    _fileSize = 0;
    
    assert(self.networkStream == nil);
    assert(self.fileStream == nil);

    NSLog(@"write to: ");
    NSString *filename = [NSString stringWithFormat:@"%@/%@", [self.url host],[self.url path]];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:filename];
    self.fileStream = [NSOutputStream outputStreamToFileAtPath:filePath append:NO];
    [self.fileStream open];        

    
    BOOL success;
    CFReadStreamRef ftpStream;
    
    assert(self.networkStream == nil);
    
    // Open a CFFTPStream for the URL
    ftpStream = CFReadStreamCreateWithFTPURL(NULL, (CFURLRef)self.url);
    assert(ftpStream != NULL);
    
    self.networkStream = (NSInputStream *)ftpStream;
    if([self.username length] > 0 && [self.password length] > 0) {
        success = [self.networkStream setProperty:self.username forKey:(id)kCFStreamPropertyFTPUserName];
        assert(success);
        
        success = [self.networkStream setProperty:self.password forKey:(id)kCFStreamPropertyFTPPassword];
        assert(success);
    }
    
    self.networkStream.delegate = self;
    [self.networkStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.networkStream open];
    
    // Have to release ftpStream to balance out the create. self.networkStream has retained this for our persistent use.
    CFRelease(ftpStream);
}

// Shuts down the connection
- (void)_stopReceiveWithStatus:(NSString *)statusString {    
    if (self.networkStream != nil) {
        NSLog(@"%s : %@", __PRETTY_FUNCTION__, statusString);
        [self.networkStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        self.networkStream.delegate = nil;
        [self.networkStream close];
        self.networkStream = nil;
    }
    
    
    if(self.fileStream != nil) {
        [self.fileStream close];
        self.fileStream = nil;
    }
}

- (NSDictionary *)_entryByReencodingNameInEntry:(NSDictionary *)entry encoding:(NSStringEncoding)newEncoding {
    NSDictionary *result;
    NSString *name;
    NSData *nameData;
    NSString *newName;
    
    newName = nil;
    
    // Try to get the name, convert it back to MacRoman, and then reconvert it with the preferred encoding.
    name = [entry objectForKey:(id) kCFFTPResourceName];
    if(name != nil) {
        assert([name isKindOfClass:[NSString class]]);
        
        nameData = [name dataUsingEncoding:NSMacOSRomanStringEncoding];
        if (nameData != nil) {
            newName = [[[NSString alloc] initWithData:nameData encoding:newEncoding] autorelease];
        }
    }
    
    // If the above failed, just return the entry unmodified. 
    // If it succeeded, make a copy of the entry and replace the name with the new name that we calculated.
    if(newName == nil) {
        //assert(NO);
        result = (NSDictionary *)entry;
    } else {
        NSMutableDictionary *newEntry;
        
        newEntry = [[entry mutableCopy] autorelease];
        assert(newEntry != nil);                    
        
        [newEntry setObject:newName forKey:(id) kCFFTPResourceName];
        result = newEntry;
    }
    
    return result;
}


- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
#pragma anused(aStream)
    assert(aStream == self.networkStream);
    
    switch (eventCode) {
        case NSStreamEventOpenCompleted: {
            //
        } break;
            
        case NSStreamEventHasBytesAvailable: {
            NSUInteger bytesRead;
            uint8_t buffer[1024*1024];//32768*2];
            
            // Pull some data of the network
            bytesRead = [self.networkStream read:buffer maxLength:sizeof(buffer)];
            if (bytesRead == -1) {
                [self _stopReceiveWithStatus:@"Network read error"];
            } else if(bytesRead == 0) {
                [self _stopReceiveWithStatus:nil];
                
                // downloaded, so notificate
                [self.delegate handleLoadingDidEndNotification:self];                                
            } else {
                NSInteger bytesWritten;
                NSInteger bytesWrittensoFar;
                    
                // Write to the file
                bytesWrittensoFar = 0;
                do {
                    bytesWritten = [self.fileStream write:&buffer[bytesWrittensoFar] maxLength:bytesRead - bytesWrittensoFar];
                    assert(bytesWritten != 0);
                    if(bytesWritten == -1) {
                        [self _stopReceiveWithStatus:@"File write error"];
                        break;                        
                    } else {
                        bytesWrittensoFar += bytesWritten;
                    }
                } while (bytesWrittensoFar != bytesRead);
                
                // Progress notification
                if ([_delegateProgress respondsToSelector:@selector(handleLoadingProgressNotification:)]) {
                    [_delegateProgress handleLoadingProgressNotification:bytesWrittensoFar];
                }
                //_fileSize += bytesWrittensoFar;
            }
        } break;
            
        case NSStreamEventHasSpaceAvailable: {
            assert(NO); // should never happen for the output stream  
        } break;
            
        case NSStreamEventErrorOccurred: {
            [self _stopReceiveWithStatus:@"Stream open error"];
        } break;
            
        case NSStreamEventEndEncountered: {
            // ignore
        } break;
            
            
        default: {
            assert(NO);
        } break;
    }
}
    


- (void)dealloc {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    [self _stopReceiveWithStatus:@"Stopped"];
    [self.fileStream release];
    [self.networkStream release];
    
    [super dealloc];
}

/*
- (id)copyWithZone:(NSZone *)zone {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    FtpDownloader *newCopy = [super copyWithZone: zone];
    
    [newCopy setFileStream:self.fileStream];
    [newCopy setNetworkStream:self.networkStream];
    
    return newCopy;
}
*/

@end

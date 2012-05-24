//
//  FtpDownloader.m
//  PhotoBrowser
//
//  Created by ukv on 5/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//


#import "FtpDownloader.h"
#import "LoadingDelegate.h"
#import "Photo.h"

#import <CFNetwork/CFNetwork.h>

@implementation FtpDownloader


- (void)dealloc {
    NSLog(@"%s", __PRETTY_FUNCTION__);    
    if ([self isReceiving]) {
        [self _stopReceiveWithStatus:@"Stopped"];
    }
    
    [super dealloc];
}

- (void)startReceive {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
//    _fileSize = 0;
    
    assert(self.networkStream == nil);
    assert(self.fileStream == nil);

    self.fileStream = [NSOutputStream outputStreamToFileAtPath:[self pathToDownload] append:NO];
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
    if (statusString != nil) {
        NSLog(@"%s : %@", __PRETTY_FUNCTION__, statusString);
    }

    if (self.networkStream != nil) {
        
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
                if([self.delegate respondsToSelector:@selector(handleLoadingDidEndNotification:)]) {
                    [self.delegate handleLoadingDidEndNotification:self];                               
                }
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
                if ([self.delegateProgress respondsToSelector:@selector(handleLoadingProgressNotification:)]) {
                    [self.delegateProgress handleLoadingProgressNotification:bytesWrittensoFar];
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


@end

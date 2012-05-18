//
//  FtpLs.m
//  PhotoBrowser
//
//  Created by ukv on 5/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FtpLs.h"
#import "LoadingDelegate.h"
#import "EntryLs.h"
#import <CFNetwork/CFNetwork.h>

@interface FtpLs () {
    NSMutableData *_listData;
    NSInputStream *_networkStream;        
}

@property (nonatomic, readonly) BOOL isReceiving;
@property (nonatomic, retain) NSInputStream *networkStream;
@property (nonatomic, retain) NSMutableData *listData;

@end

@implementation FtpLs


@synthesize networkStream = _networkStream;
@synthesize listData = _listData;


- (id)initWithURL:(NSURL *)url {
    NSLog(@"%s", __PRETTY_FUNCTION__);

    if((self = [super initWithURL:url])) {
        //
    }
    
    return self;
}

- (BOOL)isDownloadable {
    return true;
}


- (void)_addListEntries:(NSArray *)newEntries {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    assert(self.listEntries != nil);
        


    [self.listEntries addObjectsFromArray:newEntries];
    [self sortByName];

    // Notificate delegate
    [self.delegate handleLoadingDidEndNotification:self];
}

- (BOOL)isReceiving {
    return (self.networkStream != nil);
}


- (void)startReceive {
//    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSLog(@"%s: %@", __PRETTY_FUNCTION__, self.url);
    
    [self.listEntries removeAllObjects];
        
    BOOL success;
    CFReadStreamRef ftpStream;
    
    assert(self.networkStream == nil);
    assert(self.url != nil);
    
//    _listEntries = [NSMutableArray array];
    self.listData = [NSMutableData data];
    assert(self.listData != nil);
    
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
    
    if(self.listData != nil) {
        self.listData = nil;
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

- (void)_parseListData {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    NSMutableArray *newEntries;
    NSUInteger offset;
    
    // We accumulate the new entries into an array to avoid a) adding items one-by-one,
    // and b) repeatedly shuffling the listData buffer around.
    newEntries = [NSMutableArray array];
    assert(newEntries != nil);
    
    offset = 0;
    do {
        CFIndex bytesConsumed;
        CFDictionaryRef thisEntry;
        
        thisEntry = NULL;
        
        assert(offset <= self.listData.length);
        bytesConsumed = CFFTPCreateParsedResourceListing(NULL, &((const uint8_t *) self.listData.bytes)[offset], 
                                                         self.listData.length - offset, &thisEntry);
        if (bytesConsumed > 0) {
            if(thisEntry != NULL) {
                
                // add only directories and image files
//                if(([self isDirectory:(NSDictionary *)thisEntry] || [self isImageFile:(NSDictionary *)thisEntry])) {
                    EntryLs *entryToAdd = [[EntryLs alloc] initWithDictionaryEntry:[self _entryByReencodingNameInEntry:(NSDictionary *)thisEntry encoding:NSUTF8StringEncoding]];
                    
                    [newEntries addObject:entryToAdd];
                    [entryToAdd release];
//                }
            }
            // We consume the bytes regardless of whether we get an entry.
            offset += bytesConsumed;
        }
        
        if (thisEntry != NULL) {
            CFRelease(thisEntry);
        }
        
        if (bytesConsumed == 0) {
            // We haven't yet got enough data to parse an entry. Wait for more data to arrive.
            break;
        } else if(bytesConsumed < 0) {
            // We totally failed to parse the listing. Fail
            break;
        }
    } while (YES);
    
    if (newEntries.count != 0) {
        [self _addListEntries:newEntries];
    }
    
    if (offset != 0) {
        [self.listData replaceBytesInRange:NSMakeRange(0, offset) withBytes:NULL length:0];
    }
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
            uint8_t buffer[32768];
            
            // Pull some data of the network
            bytesRead = [self.networkStream read:buffer maxLength:sizeof(buffer)];
            if (bytesRead == -1) {
                [self _stopReceiveWithStatus:@"Network read error"];
            } else if(bytesRead == 0) {
                [self _stopReceiveWithStatus:nil];
                // downloaded
                
            } else {
                assert(self.listData != nil);
                
                // Append the data to our listing buffer.
                [self.listData appendBytes:buffer length:bytesRead];
                
                // Check the listing buffer for any complete entries and update the UI if we find any.                                                                                                                
                [self _parseListData];
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
   
    
    [super dealloc];
}

/*
- (id)copyWithZone:(NSZone *)zone {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    FtpLs *newCopy = [super copyWithZone: zone];
    
    [newCopy setListEntries:self.listEntries];
    [newCopy setNetworkStream:self.networkStream];
    [newCopy setListData:self.listData];
    
    return newCopy;
}
*/

@end

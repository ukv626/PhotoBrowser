//
//  Image.m
//  PhotoBrowser
//
//  Created by ukv on 4/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Photo.h"
#import "Browser.h"
#import <CFNetwork/CFNetwork.h>

// Private
@interface Photo() {
    
    // Image sources
    NSUInteger _photoNumber;
    NSString *_photoPath;
    NSURL *_photoURL;
    
    // Image
    UIImage *_underlyingImage;
    
    // Ftp
    NSInputStream *_networkStream;
    NSOutputStream *_fileStream;
    
    // Other
    NSString *_caption;
    BOOL _loadingProgress;
}

// Properties
@property (nonatomic, retain) UIImage *underlyingImage;
@property (nonatomic, readonly) BOOL isReceiving;
@property (nonatomic, retain) NSInputStream *networkStream;
@property (nonatomic, retain) NSOutputStream *fileStream;
@property (nonatomic, retain) NSURL *photoURL;
//@property (nonatomic, retain) NSString *photoPath;

// Methods
- (void)imageDidFinishLoadingSoDecompress;
- (void)imageLoadingComplete;
@end

@implementation Photo

@synthesize underlyingImage = _underlyingImage, caption = _caption;
@synthesize photoNumber = _photoNumber;


#pragma mark Class Methods

+ (Photo *)photoWithImage:(UIImage *)image {
    return [[[Photo alloc] initWithImage:image] autorelease];
}

+ (Photo *)photoWithFilePath:(NSString *)path {
    return [[[Photo alloc] initWithFilePath:path] autorelease];
}

+ (Photo *)photoWithURL:(NSURL *)url {
    return [[[Photo alloc] initWithURL:url] autorelease];
}

#pragma mark NSObject

- (id)initWithImage:(UIImage *)image {
    if((self = [super init])) {
        self.underlyingImage = image;
    }
    return self;
}

- (id)initWithFilePath:(NSString *)path {
    if ((self = [super init])) {
        self.photoPath = [path copy];
    }
    return  self;
}

- (id)initWithURL:(NSURL *)url {
    if ((self = [super init])) {
        self.photoURL = [url copy];
        
        NSString *filename = [self.photoURL path]; //lastPathComponent];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        self.photoPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:filename];

//        self.photoPath = [NSTemporaryDirectory() stringByAppendingPathComponent:filename];
        //[[AppDelegate sharedAppDelegate] pathForTemporaryFileWithPrefix:@"Get"];
    }
    return self;
}

- (void)dealloc {
    [self _stopReceivingWithStatus:@"Stopped"];
    [_photoPath release];
    [_photoURL release];
    [_underlyingImage release];
    
    [super dealloc];
}


#pragma  mark Photo Protocol Methods

- (UIImage *)underlyingImage {
    return _underlyingImage;
}

- (BOOL)fileExist {
    BOOL result = NO;
    
    if([[NSFileManager defaultManager] fileExistsAtPath:self.photoPath]) {
        result = YES;
    }
    
    return result;
}

- (void)loadUnderlyingImageAndNotify {
    NSAssert([[NSThread currentThread] isMainThread], @"This method must be called on the main thread.");
    
    if(_loadingProgress == YES)
        return;
    
    _loadingProgress = YES;
    if(self.underlyingImage) {
        // Image already loaded
        [self imageLoadingComplete];
    } else {
        if([self fileExist]) {
            // Load async from file
            [self performSelectorInBackground:@selector(loadImageFromFileAsync) withObject:nil];
        } else if(_photoURL){
            [self _startReceive];
            
        } else {
            // Failed - no source
            self.underlyingImage = nil;
            [self imageLoadingComplete];
        }
    }        
}

// Release if we can get it again from path or url
- (void)unloadUnderlyingImage {    
    _loadingProgress = NO;
    if(self.underlyingImage && _photoPath) {
        NSLog(@"%s: %@", __PRETTY_FUNCTION__, _photoPath);
        self.underlyingImage = nil;
    }       
}


#pragma mark - Async Loading

// Called in background
// Load image in background from local file
- (void)loadImageFromFileAsync {
//    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    @try {
        NSError *error = nil;
        NSData *data = [NSData dataWithContentsOfFile:_photoPath options:NSDataReadingUncached error:&error];
        if(!error) {
            self.underlyingImage = [[[UIImage alloc] initWithData:data] autorelease];
        } else {
            self.underlyingImage = nil;
            NSLog(@"Photo from file error: %@", error);
        }
    }
    @catch (NSException *exception) {        
    }
    @finally {
        [self performSelectorOnMainThread:@selector(imageDidFinishLoadingSoDecompress) withObject:nil waitUntilDone:NO];
        [pool drain];        
    }
}

// Called on main
- (void)imageDidFinishLoadingSoDecompress {
    NSAssert([[NSThread currentThread] isMainThread], @"This method must be called on the main thread.");
    if(self.underlyingImage) {
        // Decode image async to avoid lagging when UIKit lazy loads
        //
    } else {
        // Failed
    }
    [self imageLoadingComplete];
}

- (void)imageLoadingComplete {
    NSAssert([[NSThread currentThread] isMainThread], @"This method must be called on the main thread.");
    // Complete so notify
    _loadingProgress = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:PHOTO_LOADING_DID_END_NOTIFICATION object:self];
}

#pragma mark Core Transfer code
@synthesize networkStream = _networkStream;
@synthesize fileStream = _fileStream;
@synthesize photoURL = _photoURL;
@synthesize photoPath = _photoPath;

- (BOOL)isReceiving {
    return (self.networkStream != nil);
}

- (void)_startReceive {
//    BOOL success;
    CFReadStreamRef ftpStream;
    
    assert(self.networkStream == nil);
    assert(self.fileStream == nil);
    
    // Open a stream for the file we're going to recieve into
    NSLog(@"write to: %@", self.photoPath);
    self.fileStream = [NSOutputStream outputStreamToFileAtPath:self.photoPath append:NO];
    [self.fileStream open];
    
    // Open a CFFTPStream for the URL
    ftpStream = CFReadStreamCreateWithFTPURL(NULL, (CFURLRef)self.photoURL);
    assert(ftpStream != NULL);
    self.networkStream = (NSInputStream *)ftpStream;
    BOOL success;
    success = [self.networkStream setProperty:@"ukv" forKey:(id)kCFStreamPropertyFTPUserName];
    assert(success);
    success = [self.networkStream setProperty:@"njgktcc" forKey:(id)kCFStreamPropertyFTPPassword];
    assert(success);
    
    self.networkStream.delegate = self;
    [self.networkStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.networkStream open];
    
    // Have to release ftpStream to balance out the create. self.networkStream has retained this for out persistent use
    CFRelease(ftpStream);            
}


// Shuts down the connection and dislays the result
- (void)_stopReceivingWithStatus:(NSString *)statusString {
//    NSLog(@"stopWith: %@",statusString);
    if(self.networkStream != nil) {
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

// An NSStream delegate callback that's called when events happen on our network stream
- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {    
    assert(aStream == self.networkStream);
    
    switch (eventCode) {
            
        case NSStreamEventOpenCompleted: {
//            NSLog(@"Opened connection");
        } break;
            
        case NSStreamEventHasBytesAvailable: {
            NSInteger bytesRead;
            uint8_t buffer[32768];
            
//            NSLog(@"Receiving");
            // Pull some data off the network
            bytesRead = [self.networkStream read:buffer maxLength:sizeof(buffer)];
            if(bytesRead == -1) {
                [self _stopReceivingWithStatus:@"Network read error"];
            } else if(bytesRead == 0) {
                [self _stopReceivingWithStatus:nil];
                // downloaded
                [self loadImageFromFileAsync];
            } else {
                NSInteger bytesWritten;
                NSInteger bytesWrittensoFar;
                
                // Write to the file
                bytesWrittensoFar = 0;
                do {
                    bytesWritten = [self.fileStream write:&buffer[bytesWrittensoFar] maxLength:bytesRead - bytesWrittensoFar];
                    assert(bytesWritten != 0);
                    if(bytesWritten == -1) {
                        [self _stopReceivingWithStatus:@"File write error"];
                        break;
                    } else {
                        bytesWrittensoFar += bytesWritten;
                    }
                } while (bytesWrittensoFar != bytesRead);                                    
            }
        } break;
            
        case NSStreamEventHasSpaceAvailable: {
            assert(NO);
        } break;
            
        case NSStreamEventErrorOccurred: {
            [self _stopReceivingWithStatus:@"Stream open error"];
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

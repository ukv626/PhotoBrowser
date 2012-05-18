//
//  LocalLs.m
//  PhotoBrowser
//
//  Created by ukv on 5/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LocalLs.h"
#import "EntryLs.h"
#import "LoadingDelegate.h"

@implementation LocalLs

- (id)initWithURL:(NSURL *)url {
    NSLog(@"%s [%@]", __PRETTY_FUNCTION__, url);
    
    if((self = [super initWithURL:url])) {
        //
    }
    
    return self;
}

- (void)dealloc {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    [super dealloc];
}

- (void)startReceive {
//    NSLog(@"%s [%@]", __PRETTY_FUNCTION__, [self.url absoluteString]);
    
    [self.listEntries removeAllObjects];
    
    NSArray *properties = [NSArray arrayWithObjects: NSURLLocalizedNameKey,
                           NSURLCreationDateKey, NSURLLocalizedTypeDescriptionKey, nil];
    
    NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:self.url includingPropertiesForKeys:properties options:(NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsHiddenFiles) error:nil];
    
    
    NSDictionary *attribs;
    
    for (NSURL *entry in dirContents) {
        EntryLs *entryToAdd = [[EntryLs alloc] init];
        entryToAdd.text = [entry lastPathComponent];
        
        attribs = [[NSFileManager defaultManager] attributesOfItemAtPath:[entry path]  error:nil];
        if ([attribs objectForKey:(id)NSFileType] == NSFileTypeDirectory) {
            entryToAdd.isDir = YES;
        } else {
            entryToAdd.isDir = NO;
        }
        
        entryToAdd.date = [attribs objectForKey:(id)NSFileModificationDate];        
        NSNumber *size;
        size = [attribs objectForKey:(id)NSFileSize];
        if(size != nil) {
            entryToAdd.size = [size unsignedLongLongValue];
            
        }
        
        [self.listEntries addObject:entryToAdd];
        [entryToAdd release];
    }
    //[properties release];
    //[dirContents release];
    [self sortByName];
    
    // Notificate delegate
    [self.delegate handleLoadingDidEndNotification:self];
}

@end

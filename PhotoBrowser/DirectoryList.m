//
//  DirectoryList.m
//  PhotoBrowser
//
//  Created by ukv on 5/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DirectoryList.h"
#include <sys/dirent.h>

#import "Browser.h"

@interface DirectoryList () {
    NSURL *_url;
    UIActivityIndicatorView *_activityIndicator;
    NSInputStream *_networkStream;
    NSMutableData *_listData;
    NSMutableArray *_listEntries;
    NSMutableArray *_imageEntries;
}

@property (nonatomic, readonly) BOOL isReceiving;
@property (nonatomic, retain) NSURL *url;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView * activityIndicator;
@property (nonatomic, retain) NSInputStream *networkStream;
@property (nonatomic, retain) NSMutableData *listData;
@property (nonatomic, retain) NSMutableArray *listEntries;
@property (nonatomic, retain) NSMutableArray *imageEntries;

- (BOOL)isDirectory:(NSDictionary *)entry;
- (BOOL)isImageFile:(NSDictionary *)entry;
- (void)createDirectory:(NSString *)path;

@end

@implementation DirectoryList

#pragma mark * Status management
// These methods are used by the core transfer to update the UI.

- (void)_receiveDidStart {
    [self.tableView reloadData];
    [self.activityIndicator startAnimating];
}

- (void)_updateStatus {
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
    
}

- (void)_addListEntries:(NSArray *)newEntries {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    assert(self.listEntries != nil);
    
    for (NSDictionary *entry in newEntries) {                                            
        if([self isDirectory:entry] || [self isImageFile:entry]) {
            [self.listEntries addObject:entry];
        }
    }
    
    
    NSArray *sortedEntries;
    sortedEntries = [self.listEntries sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        if([obj1 isKindOfClass:[NSDictionary class]] && [obj2 isKindOfClass:[NSDictionary class]]) {
            NSNumber *typeNum1 = [obj1 objectForKey:(id) kCFFTPResourceType];
            NSNumber *typeNum2 = [obj2 objectForKey:(id) kCFFTPResourceType];
            
            if(typeNum1 != nil && typeNum2 != nil) {           
                return [typeNum1 intValue] > [typeNum2 intValue];
            }
            
        }
        return (NSComparisonResult)NSOrderedSame;
    }];
    
    self.listEntries = (NSMutableArray *)sortedEntries; // addObjectsFromArray:sortedEntries];
    [self.tableView reloadData];
}

- (void)_receiveDidStop {
    [self.activityIndicator stopAnimating];
}

#pragma mark * Core transfer code

// This is code that actually does the networking.

// Properties
@synthesize url = _url;
@synthesize networkStream = _networkStream;
@synthesize listData = _listData;
@synthesize listEntries = _listEntries;
@synthesize imageEntries = _imageEntries;
@synthesize activityIndicator = _activityIndicator;

- (BOOL)isReceiving {
    return  (self.networkStream != nil);
}


- (void)_startReceive {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    BOOL success;
    CFReadStreamRef ftpStream;
    
    assert(self.networkStream == nil);
    success = (self.url != nil);
        
    self.listEntries = [NSMutableArray array];
    self.imageEntries = nil;
    self.listData = [NSMutableData data];
    assert(self.listData != nil);
    
    // Open a CFFTPStream for the URL
    ftpStream = CFReadStreamCreateWithFTPURL(NULL, (CFURLRef)self.url);
    assert(ftpStream != NULL);
    
    self.networkStream = (NSInputStream *)ftpStream;
    success = [self.networkStream setProperty:@"ukv" forKey:(id)kCFStreamPropertyFTPUserName];
    assert(success);
    success = [self.networkStream setProperty:@"njgktcc" forKey:(id)kCFStreamPropertyFTPPassword];
    assert(success);
    
    self.networkStream.delegate = self;
    [self.networkStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.networkStream open];
    
    // Have to release ftpStream to balance out the create. self.networkStream has retained this for our persistent use.
    CFRelease(ftpStream);
    
    // Tell the UI we're receiving.
    [self _receiveDidStart];
}

- (void)_stopReceiveWithStatus:(NSString *)statusString {
    NSLog(@"%s : %@", __PRETTY_FUNCTION__, statusString);
    if (self.networkStream != nil) {
        [self.networkStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        self.networkStream.delegate = nil;
        [self.networkStream close];
        self.networkStream = nil;
    }
    [self _receiveDidStop];
    self.listData = nil;
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
                NSDictionary *entryToAdd;
                
                entryToAdd = [self _entryByReencodingNameInEntry:(NSDictionary *)thisEntry encoding:NSUTF8StringEncoding];                
                [newEntries addObject:entryToAdd];
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




#pragma mark - Table view data source and delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return _listEntries.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell...
    if(cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
    NSDictionary *listEntry = [_listEntries objectAtIndex:indexPath.row];
    assert([listEntry isKindOfClass:[NSDictionary class]]);
    
    cell.textLabel.text = [listEntry objectForKey:(id) kCFFTPResourceName];
    
    int type;
    NSNumber *typeNum;
    NSNumber *modeNum;
    char  modeCStr[12];
    
    // Use the second line of the cell to show various attributes
    
    typeNum = [listEntry objectForKey:(id) kCFFTPResourceType];
    if(typeNum != nil) {
        assert([typeNum isKindOfClass:[NSNumber class]]);
        type = [typeNum intValue];
    } else {
        type = 0;
    }
    
    modeNum = [listEntry objectForKey:(id) kCFFTPResourceMode];
    if(modeNum != nil) {
        assert([modeNum isKindOfClass:[NSNumber class]]);
        strmode([modeNum intValue] + DTTOIF(type), modeCStr);
    }
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%s [%d]", modeCStr, type];
    if(type == 4) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
//    NSLog(@"%s", __PRETTY_FUNCTION__);
    // Navigation logic may go here. Create and push another view controller.
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    
    
    if(cell.accessoryType == UITableViewCellAccessoryDisclosureIndicator) {                
        NSString *entryName = cell.textLabel.text;
        DirectoryList *dirList = [[DirectoryList alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/", [_url absoluteString], [entryName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]]];
        //    dirList.listEntries = ftpLs.listEntries;
        
        [self.navigationController pushViewController:dirList animated:YES];
        
        // Release
        [dirList release];
    } else {
        if(self.imageEntries == nil) {
            self.imageEntries = [NSMutableArray array];
            
            for (NSDictionary *entry in self.listEntries) {                                            
                if([self isImageFile:entry]) {
                    NSString *filename = [entry objectForKey:(id) kCFFTPResourceName];
                    NSString *fileURL = [[self.url absoluteString] stringByAppendingString:[filename stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                    NSLog(@"%@", fileURL);
                                          
                    Photo *photo = [[Photo alloc]initWithURL:[NSURL URLWithString:fileURL]];
                    [self.imageEntries addObject:photo];
                }
            }                                 
        }

        [self createDirectory:[self.url path]];

        Browser *browser = [[Browser alloc]initWithPhotos:self.imageEntries photosPerPage:1];
        //browser.photosPerPage = 1;
        [browser setInitialPageIndex:(indexPath.row - ([self.listEntries count] - [self.imageEntries count]))];
        [self.navigationController pushViewController:browser animated:YES];
        // Release
        [browser release];
    }
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     [detailViewController release];
     */
}




- (BOOL)isDirectory:(NSDictionary *)entry {
    BOOL result = NO;
    
    assert(entry != nil);
    
    NSNumber *typeNum = [entry objectForKey:(id) kCFFTPResourceType];
    int type = typeNum != nil ? [typeNum intValue] : 0;
    
    if(type == 4)
        result = YES;
    
    return result;
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

- (void)createDirectory:(NSString *)dirName {
    NSString *path;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    path = [[paths objectAtIndex:0] stringByAppendingPathComponent:dirName];
    NSError *error;
    
//    NSLog(@"%@", path);
    if(![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        if(![[NSFileManager defaultManager] createDirectoryAtPath:path 
                                      withIntermediateDirectories:YES attributes:nil error:&error]) {
            NSLog(@"Create directory error: %@", error);
            
        }
    }
    
}

#pragma mark * View controller boilerplate

- (id)initWithURL:(NSURL *)url
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        // Custom initialization
        _url = [url copy];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = [_url lastPathComponent];

    if(self.activityIndicator == nil) {
        self.activityIndicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [self.view addSubview:self.activityIndicator];
        
        CGRect frame = self.view.bounds;
        CGRect indFrame = self.activityIndicator.bounds;
                
        // Position the indicator
        indFrame.origin.x = floorf((frame.size.width - indFrame.size.width) / 2);
        indFrame.origin.y = floorf((frame.size.height - indFrame.size.height) / 2);
        self.activityIndicator.frame = indFrame;        
    }            
    
    if(self.listEntries == nil) {
        self.listEntries = [[NSMutableArray alloc] init];
    }
    
    assert(self.listEntries != nil);
    assert(self.activityIndicator != nil);

    
    //self.activityIndicator.hidden = YES;
    [self _startReceive];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    self.activityIndicator = nil;
    
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)dealloc {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self _stopReceiveWithStatus:@"Stopped"];
    [_listEntries release];
    [_activityIndicator release];
    
    [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

@end

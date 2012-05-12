//
//  DirectoryList.m
//  PhotoBrowser
//
//  Created by ukv on 5/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DirectoryList.h"
#include <sys/dirent.h>

#import "BaseLs.h"
#import "Browser.h"


@interface DirectoryList () {
    BaseLs *_driver;
    
    NSURL *_url;
    NSArray *_listEntries;
    NSMutableArray *_imageEntries;
        
    UIActivityIndicatorView *_activityIndicator;
}

@property (nonatomic, retain) BaseLs *driver;
@property (nonatomic, copy) NSURL *url;
@property (nonatomic, copy) NSArray *listEntries;
@property (nonatomic, retain) NSMutableArray *imageEntries;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView * activityIndicator;


@end

@implementation DirectoryList

#pragma mark * Status management
// These methods are used by the core transfer to update the UI.

- (void)_receiveDidStart {
    //[self.tableView reloadData];
    [self.activityIndicator startAnimating];
}

- (void)_updateStatus {
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
    
}


- (void)_receiveDidStop {
    [self.activityIndicator stopAnimating];
}

#pragma mark * Core transfer code

// This is code that actually does the networking.

// Properties


@synthesize driver = _driver;
@synthesize url = _url;
@synthesize listEntries = _listEntries;
@synthesize imageEntries = _imageEntries;
@synthesize activityIndicator = _activityIndicator;

#pragma mark - Table view data source and delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.listEntries.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell...
    if(cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
    NSDictionary *listEntry = [self.listEntries objectAtIndex:indexPath.row];
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
            
        self.driver.url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/", [self.url absoluteString], [entryName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
        
        DirectoryList *dirList = [[DirectoryList alloc] initWithDriver:self.driver];
        
        [self.navigationController pushViewController:dirList animated:YES];
        
        // Release
        [dirList release];         
    } else {
        NSLog(@"listEntries:%d imageEntries:%d [%@]", [self.listEntries count], [self.imageEntries count], self.url);
        
        if(self.imageEntries == nil) {
            self.imageEntries = [NSMutableArray array];
            
            for (NSDictionary *entry in self.listEntries) {                                            
                if([self.driver isImageFile:entry]) {
                    NSString *filename = [entry objectForKey:(id) kCFFTPResourceName];
                    NSString *fileURL = [[self.url absoluteString] stringByAppendingString:[filename stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                    //NSLog(@"%@", fileURL);
                                          
                    Photo *photo = [[Photo alloc]initWithURL:[NSURL URLWithString:fileURL]];
                    photo.username = self.driver.username;
                    photo.password = self.driver.password;
                    [self.imageEntries addObject:photo];
                    
                    [photo release];
                }
            }                                 
        }

        [self.driver createDirectory:[NSString stringWithFormat:@"%@/%@", [self.driver.url host],[self.driver.url path]]];

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


- (void)handleDirLoadingDidEndNotification:(NSNotification *)notification {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    self.listEntries = self.driver.listEntries;
    [self.tableView reloadData];
    
    [self _receiveDidStop];
    [[NSNotificationCenter defaultCenter] removeObserver:self];    
}

#pragma mark * View controller boilerplate

- (id)initWithDriver:(BaseLs *)driver {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        // Custom initialization
        self.driver = driver; //[driver retain];
        self.url = self.driver.url;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = [self.url lastPathComponent];
    if([self.title length] == 0) {
        self.title = [self.url host];
    }

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
    
    assert(self.activityIndicator != nil);

    
    //self.activityIndicator.hidden = YES;
    
    // Listen for Driver notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleDirLoadingDidEndNotification:)
                                                 name:DIRLIST_LOADING_DID_END_NOTIFICATION
                                               object:nil];

    
    [self.driver startReceive];
    [self _receiveDidStart];
    
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
    
    [_driver release];
    [_url release];
    [_imageEntries release];
    [_activityIndicator release];
    
    [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

@end
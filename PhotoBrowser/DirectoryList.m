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
#import "FtpDownloader.h"
#import "EntryLs.h"


@interface DirectoryList () {
    FtpLs *_driver;
    
    NSMutableArray *_filteredListEntries;
    IBOutlet UISearchBar *_searchBar;
    BOOL _searching;
    BOOL _letUserSelectRow;
        
    UIActivityIndicatorView *_activityIndicator;
}

- (void)searchTableView;
- (void)doneSearching_Clicked:(id)sender;

@end

@implementation DirectoryList

#pragma mark * Status management
// These methods are used by the core transfer to update the UI.

- (void)_receiveDidStart {
    //[self.tableView reloadData];
    [_activityIndicator startAnimating];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDirLoadingDidEndNotification:) name:DIRLIST_LOADING_DID_END_NOTIFICATION object:nil];
}

- (void)_updateStatus {
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
    
}


- (void)_receiveDidStop {
    [_activityIndicator stopAnimating];
}

#pragma mark * Core transfer code

// This is code that actually does the networking.

// Properties


#pragma mark - Table view data source and delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if(_searching) {
        return [_filteredListEntries count];
    } else {
        return _driver.listEntries.count;
    }
}

- (NSString *)_stringForNumber:(double)num asUnits:(NSString *)units {
    NSString *result;
    double fractional;
    double integral;
    
    fractional = modf(num, &integral);
    if((fractional < 0.1) || (fractional > 0.9)) {
        result = [NSString stringWithFormat:@"%.0f %@", round(num), units];
    } else {
        result = [NSString stringWithFormat:@"%.1f %@", num, units];
    }
    
    return  result;
}

- (NSString *)_stringForFileSize:(unsigned long long)fileSizeExact {
    double  fileSize;
    NSString *  result;
    
    fileSize = (double) fileSizeExact;
    if (fileSizeExact == 1) {
        result = @"1 byte";
    } else if (fileSizeExact < 1024) {
        result = [NSString stringWithFormat:@"%llu bytes", fileSizeExact];
    } else if (fileSize < (1024.0 * 1024.0 * 0.1)) {
        result = [self _stringForNumber:fileSize / 1024.0 asUnits:@"KB"];
    } else if (fileSize < (1024.0 * 1024.0 * 1024.0 * 0.1)) {
        result = [self _stringForNumber:fileSize / (1024.0 * 1024.0) asUnits:@"MB"];
    } else {
        result = [self _stringForNumber:fileSize / (1024.0 * 1024.0 * 1024.0) asUnits:@"MB"];
    }
    
    return result;
}

static NSDateFormatter *sDateFormatter;

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell...
    if(cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
    EntryLs *listEntry;
    if(_searching) {
        listEntry = [_filteredListEntries objectAtIndex:indexPath.row];
    } else {
        listEntry = [_driver.listEntries objectAtIndex:indexPath.row];
    }

    assert([listEntry isKindOfClass:[EntryLs class]]);
                
    // Use the second line of the cell to show various attributes    
    // File Size
    NSString *sizeStr = [listEntry isDir] ? @"" : [self _stringForFileSize:[listEntry size]];
    
    // Modification date
    if (sDateFormatter == nil) {
        sDateFormatter = [[NSDateFormatter alloc] init];
        assert(sDateFormatter != nil);
        
        sDateFormatter.dateStyle = NSDateFormatterShortStyle;
        sDateFormatter.timeStyle = NSDateFormatterShortStyle;
    }
    NSString *dateStr = [sDateFormatter stringFromDate:[listEntry date]];
    
    cell.textLabel.text = [listEntry text];
    
    
    if([listEntry isDir]) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", dateStr];
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ [%@]", dateStr, sizeStr];
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

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_letUserSelectRow) {
        return indexPath;
    } else {
        return nil;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
//    NSLog(@"%s", __PRETTY_FUNCTION__);
    // Navigation logic may go here. Create and push another view controller.
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    
    
    if(cell.accessoryType == UITableViewCellAccessoryDisclosureIndicator) {                
        
        NSString *entryName = cell.textLabel.text;
            
        FtpLs *newDriver = [[FtpLs alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/", [_driver.url absoluteString], [entryName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]]];
        newDriver.username = _driver.username;
        newDriver.password = _driver.password;
                                                      
        
        DirectoryList *dirList = [[DirectoryList alloc] initWithDriver:newDriver];
        [newDriver release];
        
        [self.navigationController pushViewController:dirList animated:YES];
        
        // Release
        [dirList release];         
    } else if([_driver isImageFile:cell.textLabel.text]) {
        NSLog(@"listEntries:%d", [_driver.listEntries count]);        
        
        [_driver createDirectory:[NSString stringWithFormat:@"%@/%@", [_driver.url host],[_driver.url path]]];
        
        NSUInteger pageIndex;
        NSUInteger i = 0;
        NSMutableArray *photos = [[NSMutableArray alloc] init];
        for (EntryLs *entry in _driver.listEntries) { 
            NSString *filename = [entry text];
            if([_driver isImageFile:filename]) {                
                NSString *fileURL = [[_driver.url absoluteString] stringByAppendingString:[filename stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                    //NSLog(@"%@", fileURL);
                if(filename == cell.textLabel.text) {
                    pageIndex = i;
                }
                                          
                FtpDownloader *newDriver = [[FtpDownloader alloc] initWithURL:[NSURL URLWithString:fileURL]];
                newDriver.username = _driver.username;
                newDriver.password = _driver.password;
                Photo *photo = [[Photo alloc] initWithDriver:newDriver];
                photo.caption = filename;
                [newDriver release];
                   
                [photos addObject:photo];
                [photo release];
                ++i;
            }
        }                                 
        

        Browser *browser = [[Browser alloc] initWithPhotos:photos photosPerPage:1];
        [browser setInitialPageIndex:pageIndex];

        [photos release];
        
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


- (void)handleLoadingDidEndNotification {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self.tableView reloadData];
    
    [self _receiveDidStop];
//    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark * View controller boilerplate

- (id)initWithDriver:(FtpLs *)driver {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        // Custom initialization
        _driver = [driver retain];
        _driver.delegate = self;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = [_driver.url lastPathComponent];
    if([self.title length] == 0) {
        self.title = [_driver.url host];
    }

    if(_activityIndicator == nil) {
        _activityIndicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [self.view addSubview:_activityIndicator];
        
        CGRect frame = self.view.bounds;
        CGRect indFrame = _activityIndicator.bounds;
                
        // Position the indicator
        indFrame.origin.x = floorf((frame.size.width - indFrame.size.width) / 2);
        indFrame.origin.y = floorf((frame.size.height - indFrame.size.height) / 2);
        _activityIndicator.frame = indFrame;        
    }            
    
    assert(_activityIndicator != nil);

    // Search Bar
    _filteredListEntries = [[NSMutableArray alloc] init];
    _searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 30)];
    _searchBar.delegate = self;
    [self.view addSubview:_searchBar];
    
    self.tableView.tableHeaderView = _searchBar;
    _searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    
    _searching = NO;
    _letUserSelectRow = YES;
    
    //_activityIndicator.hidden = YES;
    
    [self _receiveDidStart];    
    [_driver startReceive];    
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    [_activityIndicator release], _activityIndicator = nil;
    [_searchBar release], _searchBar = nil;    

    [super viewDidUnload];
}

- (void)dealloc {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    [_driver release];
    [_activityIndicator release];
    [_searchBar release];
    [_filteredListEntries release];
    
    [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

// UISearchBarDelegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    _searching = YES;
    _letUserSelectRow = NO;
    self.tableView.scrollEnabled = NO;
    
    // Add the done button
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneSearching_Clicked:)] autorelease];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    // Remove all objects first
    [_filteredListEntries removeAllObjects];
    
    if ([searchText length] > 0) {
        _searching = YES;
        _letUserSelectRow = YES;
        self.tableView.scrollEnabled = YES;
        [self searchTableView];
    } else {
        _searching = NO;
        _letUserSelectRow = NO;
        self.tableView.scrollEnabled = NO;
    }
    
    [self.tableView reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self searchTableView];
}

- (void)searchTableView {
    NSString *searchText = _searchBar.text;
    
    for(EntryLs *entry in _driver.listEntries) {
        if([[entry text] rangeOfString:searchText options:NSCaseInsensitiveSearch].location != NSNotFound) {
            [_filteredListEntries addObject:entry];
        }
    }
}

- (void)doneSearching_Clicked:(id)sender {
    _searchBar.text = @"";
    [_searchBar resignFirstResponder];
    
    _letUserSelectRow = YES;
    _searching = NO;
    self.navigationItem.rightBarButtonItem = nil;
    self.tableView.scrollEnabled = YES;
    
    [self.tableView reloadData];
}

@end

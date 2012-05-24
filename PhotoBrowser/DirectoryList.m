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
#import "BaseLs.h"
#import "FtpDownloader.h"
#import "DirectoryDownloader.h"
#import "EntryLs.h"


#define REFRESH_HEADER_HEIGHT 52.0f

@interface DirectoryList () {
    BaseLs *_driver;
    
    // ProgressView 
    UIProgressView *_progressView;
    double _totalFilesSize;
    double _downloadedFilesSize;
    
    // Toolbar
    NSMutableArray *_buttons;
    UIBarButtonItem *_backButton;
    UIBarButtonItem *_downloadButton;
    
    // URLs Stack
    NSMutableArray *_urls;
    
    NSMutableArray *_filteredListEntries;
    IBOutlet UISearchBar *_searchBar;
    BOOL _searching;
    BOOL _letUserSelectRow;
    
    DirectoryDownloader *_dirDownloader;
    FtpDownloader *_fileDownloader;
        
    UIActivityIndicatorView *_activityIndicator;
}

- (void)searchTableView;
- (void)doneSearching_Clicked:(id)sender;

@end

@implementation DirectoryList

- (id)initWithDriver:(BaseLs *)driver {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        // Custom initialization
        _driver = [driver retain];
        _driver.delegate = self;
        
        _urls = [[NSMutableArray alloc] init];
        // Push url
        [_urls addObject:_driver.url];
    }
    return self;
}

- (void)dealloc {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self _receiveDidStop];
    
    [_driver release];
    
    [_buttons release];
    [_backButton release];
    [_downloadButton release];
    
    [_searchBar release];
    [_filteredListEntries release];
    
    [_activityIndicator release];
    
    [_progressView release];
    
    [super dealloc];
}


#pragma mark * View controller boilerplate
- (void)loadView {
    [super loadView];
    
    _activityIndicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.view addSubview:_activityIndicator];
    
    CGRect frame = self.view.bounds;
    CGRect indFrame = _activityIndicator.bounds;
    
    // Position the indicator
    indFrame.origin.x = floorf((frame.size.width - indFrame.size.width) / 2);
    indFrame.origin.y = floorf((frame.size.height - indFrame.size.height) / 2);
    _activityIndicator.frame = indFrame;  
    
    assert(_activityIndicator != nil);
    
    // Toolbar
    _buttons = [[NSMutableArray alloc] init];
    _backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleBordered 
                                                  target:self action:@selector(backButton_Clicked:)];
    _backButton.enabled = NO;
//    UIBarButtonItem *sortButton = [[UIBarButtonItem alloc] initWithTitle:@"Sort" style:UIBarButtonItemStyleBordered 
//                                                                  target:self action:@selector(sortButton_Clicked:)];
    _downloadButton = [[UIBarButtonItem alloc] initWithTitle:@"Down" style:UIBarButtonItemStyleBordered 
                                                      target:self action:@selector(downloadButton_Clicked:)];
    _downloadButton.enabled = NO;
    
    [_buttons addObject:_backButton];
//    [_buttons addObject:sortButton];
    [_buttons addObject:_downloadButton];
//    [sortButton release];
    
    self.toolbarItems = _buttons;
    
    
    // SearchBar
    _filteredListEntries = [[NSMutableArray alloc] init];
    _searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 30)];
    _searchBar.delegate = self;
    [self.view addSubview:_searchBar];
    
    self.tableView.tableHeaderView = _searchBar;
    _searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    
    _searching = NO;
    _letUserSelectRow = YES;
    
    // ProgressView
    _progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 20.0)];
    _progressView.progressViewStyle = UIProgressViewStyleBar;
}


- (void)viewDidLoad {
    [super viewDidLoad];
            
    [self _receiveDidStart];       
    self.navigationController.toolbarHidden = NO;
        
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
    [_progressView release], _progressView =nil;
    
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark * Status management
// These methods are used by the core transfer to update the UI.

- (void)_receiveDidStart {
    //[self.tableView reloadData];
    UIApplication *app = [UIApplication sharedApplication];
    app.networkActivityIndicatorVisible = YES;
    
    [_activityIndicator startAnimating];
    
    [_driver startReceive];
}

- (void)_updateStatus {
//    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
}


- (void)_receiveDidStop {
    UIApplication *app = [UIApplication sharedApplication];
    app.networkActivityIndicatorVisible = NO;
    
    [_activityIndicator stopAnimating];
}

- (void)handleErrorNotification:(id)sender {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, sender);
    [self _receiveDidStop];
    NSString *errorStr = @"Connection failed!!";
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:errorStr delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    [alert show];
}

- (void)handleLoadingDidEndNotification:(id)sender {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, sender);
    
    if([[sender class] isSubclassOfClass:[BaseLs class]]) {
        // Notification from BaseLs

        self.title = [_driver.url lastPathComponent];
        if(([self.title length] == 0) || ([self.title isEqualToString:@"/"]))  {
            self.title = [_driver.url host];
        }
        
        if ([_driver isDownloadable]) {
            _downloadButton.enabled = YES;
        }
        
        if ([_urls count] > 1) {
            // Enable the Back button
            _backButton.enabled = YES;
        } else {
            _backButton.enabled = NO;
        }
        
        [self.tableView reloadData];    
        [self _receiveDidStop];
    } else if ([sender class] == [DirectoryDownloader class]) {
        // Notification from DirectoryDownloader
        NSLog(@"All items downloaded!!");
        
        _downloadButton.enabled = YES;
        self.navigationItem.titleView = nil;
        [self.navigationItem setHidesBackButton:NO animated:NO];
        
        if(_dirDownloader) {
            [_dirDownloader release];
            _dirDownloader = nil;
        }
    } else if([[sender class] isSubclassOfClass:[BaseDownloader class]]){
        NSLog(@"file downloaded");
        
        self.navigationItem.titleView = nil;
        [self.navigationItem setHidesBackButton:NO animated:NO];
        
        NSString *filePath = [sender pathToDownload];
        if([_driver isImageFile:filePath]) {
            [self showBrowser:[filePath lastPathComponent]];
        } else {
            [self showWebViewer:filePath];
         }
        
        if (_fileDownloader) {
            [_fileDownloader release];
            _fileDownloader = nil;
        }
    }
}

- (void)handleLoadingProgressNotification:(NSUInteger)value {
    // Notification from FtpDownloader
    _downloadedFilesSize += value / (1024.0 * 1024.0);
//    NSLog(@"downloaded: %.2f/%.2f", _downloadedFilesSize, _totalFilesSize);
    _progressView.progress = _downloadedFilesSize / _totalFilesSize;
}

- (void)backButton_Clicked:(id)sender {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    // Pop url
    [_urls removeObject:_driver.url];
    
    assert([_urls count] >= 1);
    _driver.url = [_urls objectAtIndex:[_urls count] - 1];
    [_driver startReceive];
}

- (void)sortButton_Clicked:(id)sender {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
}

- (void)downloadButton_Clicked:(id)sender {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    if (![_driver isDownloadable]) {
        return;
    }
    
    _dirDownloader = [[DirectoryDownloader alloc] initWithDriver:_driver];
    if(_dirDownloader != nil) {
        _dirDownloader.delegate = self;
        [_driver createDirectory];
        
        _downloadButton.enabled = NO;
        _downloadedFilesSize = 0.0;
        _totalFilesSize = 0.0;
        for (EntryLs *entry in _driver.listEntries) {
            if(![entry isDir]) {
                _totalFilesSize += [entry size] / (1024.0 * 1024.0);
            }
        }
        
        self.navigationItem.titleView = _progressView;
        [self.navigationItem setHidesBackButton:YES animated:NO];
        
        [_dirDownloader startReceive];
    }
}

- (void)showBrowser:(NSString *)currentFilename {
    NSUInteger pageIndex = 0;
    NSUInteger i = 0;
    NSMutableArray *photos = [[NSMutableArray alloc] init];
    for (EntryLs *entry in _driver.listEntries) { 
        NSString *filename = [entry text];
        if([_driver isImageFile:filename]) {                
            NSString *fileURL = [[_driver.url absoluteString] stringByAppendingString:[filename stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];

            if([filename isEqualToString:currentFilename]) pageIndex = i;
            
            FtpDownloader *downloadDriver = [[FtpDownloader alloc] initWithURL:[NSURL URLWithString:fileURL]];
            downloadDriver.username = _driver.username;
            downloadDriver.password = _driver.password;
            
            NSString *photoPath = [[_driver pathToDownload] stringByAppendingPathComponent:filename];
            Photo *photo = [[Photo alloc] initWithDriver:downloadDriver :photoPath];
            photo.caption = filename;
            [downloadDriver release];
            
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

- (void)showWebViewer:(NSString *)filepath {
    
//    NSLog(@"%s [%@]", __PRETTY_FUNCTION__, filepath);
//    WebViewer *viewer = [[WebViewer alloc] init];
    UIDocumentInteractionController *viewer = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:filepath]];
    viewer.delegate = self;
    [viewer retain];
    
    
    
//    viewer.url = [NSURL fileURLWithPath:filepath];
    if(![viewer presentPreviewAnimated:YES]) {
        NSLog(@"VIEWER: FALSE");
        [viewer release];
    }
    
//    [self.navigationController pushViewController:viewer animated:YES];
    //[viewer release];
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
        result = [self _stringForNumber:fileSize / (1024.0 * 1024.0 * 1024.0) asUnits:@"GB"];
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
    
    if ([_driver.listEntries count] == 0) {
        return cell;
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
        
        [sDateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
    }
    NSString *dateStr = [sDateFormatter stringFromDate:[listEntry date]];
    
    cell.textLabel.text = [listEntry text];
    
//    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(cell.frame.size.width-90, cell.frame.size.height-20, 88, 18)];
    
    if([listEntry isDir]) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"Modified: %@", dateStr];
//        label.text = @"";
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"Modified: %@ Size: %@", dateStr, sizeStr];
//        label.text = sizeStr;
    }
//    [cell addSubview:label];

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
        _driver.url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@/", [_driver.url absoluteString], 
                                           [cell.textLabel.text stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];

        // Push url
        [_urls addObject:_driver.url];
        [self _receiveDidStart];  
    } else {
        NSString *filePath = [[_driver pathToDownload] stringByAppendingPathComponent:cell.textLabel.text];
        // file already downloaded
        if ([_driver fileExist:filePath]) {
            NSLog(@"ALREADY DOWNLOADED");
            if([_driver isImageFile:filePath]) {
                [self showBrowser:cell.textLabel.text];
            } else {
                [self showWebViewer:filePath];
            }
        } else {
            // create dir for download files
            if ([_driver isDownloadable]) {
                [_driver createDirectory];
            }

            EntryLs *entry = [_driver.listEntries objectAtIndex:indexPath.row];
            _totalFilesSize = [entry size] / (1024.0 * 1024.0);
        
            NSString *fileURL = [[_driver.url absoluteString] stringByAppendingString:[cell.textLabel.text stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            _fileDownloader = [[FtpDownloader alloc] initWithURL:[NSURL URLWithString:fileURL]];
            _fileDownloader.username = _driver.username;
            _fileDownloader.password = _driver.password;
            _fileDownloader.delegate = self;
            _fileDownloader.delegateProgress = self;
                
            self.navigationItem.titleView = _progressView;
            [self.navigationItem setHidesBackButton:YES animated:YES];
        
            [_fileDownloader startReceive];
        }            
    }
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSLog(@"%s", __PRETTY_FUNCTION__);
    self.navigationController.toolbarHidden = NO;
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


// Pull To Refresh
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (scrollView.contentOffset.y <= -REFRESH_HEADER_HEIGHT) {
        NSLog(@"pull to refresh");
        [self _receiveDidStart];
    }
}


// UIDocumentInteractionControllerDelegate
- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller {
    return self;
}

- (void)documentInteractionControllerDidEndPreview:(UIDocumentInteractionController *)controller {
    [controller release];
}


// UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [alertView release];
    [self.navigationController popViewControllerAnimated:YES];
}

@end

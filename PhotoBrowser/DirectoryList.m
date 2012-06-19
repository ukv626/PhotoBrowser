//
//  DirectoryList.m
//  PhotoBrowser
//
//  Created by ukv on 5/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DirectoryList.h"
#include <sys/dirent.h>

#import "MWPhotoBrowser.h"
#import "BaseDriver.h"
#import "EntryLs.h"
#import "Downloads.h"

#define REFRESH_HEADER_HEIGHT 52.0f

@interface DirectoryList () {
    BaseDriver *_driver;
    BaseDriver *_fileDownloader;
    
    // ProgressView 
    UIProgressView *_progressView;

    unsigned long long _totalBytesToReceive;
    unsigned long long _bytesReceived;
    
    // Toolbar
//    UIBarButtonItem *_actionButton;
    UIBarButtonItem *_abortButton;
    UIActionSheet *_actionsSheet;
    
    // Confirmation
    UIAlertView *_downloadDirectoryConfirmation;
    
    // URLs Stack
    NSMutableArray *_urls;
    
    NSMutableArray *_filteredListEntries;
    IBOutlet UISearchBar *_searchBar;
    BOOL _searching;
    BOOL _letUserSelectRow;
        
    UIActivityIndicatorView *_activityIndicator;
    
    BOOL _directoryListReceiving;
    BOOL _fileDownloading;
}

- (void)searchTableView;
- (void)doneSearching_Clicked:(id)sender;

- (void)showBrowser:(NSString *)currentFilename;
- (void)showWebViewer:(NSString *)filepath;

@end

@implementation DirectoryList

@synthesize downloads = _downloads;

- (id)initWithDriver:(BaseDriver *)driver {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        // Custom initialization
        _driver = [driver retain];
        _driver.delegate = self;
        
        _urls = [[NSMutableArray alloc] init];
        // Push url
        [_urls addObject:_driver.url];
        _totalBytesToReceive = 0;
        
        _photos = [[NSMutableArray alloc] init];
        _dirList = [[NSMutableArray alloc] init];
        
        if ([_driver isDownloadable]) {
            self.title = @"Remote";
            self.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Remote" image:nil tag:0];
        } 
        else {
            self.tabBarItem = [[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemSearch tag:1];
        }
    }
    return self;
}

- (void)dealloc {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    _directoryListReceiving = NO;
    _fileDownloading = NO;
    [self _receiveDidStopWithActivityIndicator:YES];
    
    [_driver release];
    [_urls release];
    [_photos release];
    [_dirList release];
//    [_buttons release];
//    [_actionButton release];
    [_abortButton release];
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
//    _buttons = [[NSMutableArray alloc] init];
    _abortButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop
                                                                  target:self action:@selector(abortButtonPressed:)];
    
//    _actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction 
//                                                      target:self action:@selector(actionButtonPressed:)];
//    self.navigationItem.rightBarButtonItem =_actionButton;
//    _downloadButton.enabled = NO;
    
//    [_buttons addObject:sortButton];
//    [_buttons addObject:_downloadButton];
//    [sortButton release];
    
//    self.toolbarItems = _buttons;
    
    
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
            
    [self getDirectoryList];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    [_activityIndicator release], _activityIndicator = nil;
    [_searchBar release], _searchBar = nil;   
    [_progressView release], _progressView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark * Status management
// These methods are used by the core transfer to update the UI.

- (void)_receiveDidStartWithActivityIndicator:(BOOL)flag {
    if (flag) {
        [_activityIndicator startAnimating];
    }
    
    if (_fileDownloading) {
        _fileDownloader = [[_driver clone] retain];
        _fileDownloader.delegate = self;

        self.navigationItem.rightBarButtonItem =_abortButton;
        self.navigationItem.titleView = _progressView;
    }
    
    if (_driver.isDownloadable) {
        UIApplication *app = [UIApplication sharedApplication];
        app.networkActivityIndicatorVisible = YES;
    }
}

- (void)_receiveDidStopWithActivityIndicator:(BOOL)flag {
    if (flag) {
        [_activityIndicator stopAnimating];
    } 

    if (!_fileDownloading) {
        [_fileDownloader release];
        _fileDownloader = nil;
        
        _progressView.progress = 0;
        _totalBytesToReceive = 0;
        
        self.navigationItem.titleView = nil;
        self.navigationItem.rightBarButtonItem = nil;
    }
    
    if (_driver.isDownloadable && !_directoryListReceiving && !_fileDownloading) {
        UIApplication *app = [UIApplication sharedApplication];
        app.networkActivityIndicatorVisible = NO;
    }
}

// =====================================================================================================
// --- directoryList -----------------------------------------------------------------------------------

- (void)getDirectoryList {
    _directoryListReceiving = YES;
    [self _receiveDidStartWithActivityIndicator:YES];
    
    [self performSelectorInBackground:@selector(_getDirectoryList) withObject:nil];
}

- (void)_getDirectoryList {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    @try {
        [_driver directoryList];
    }
    @catch (NSException *exception) {        
    }
    @finally {
        [pool drain];        
    }
}

- (void)directoryListReceived {
    self.title = [_driver.url lastPathComponent];
    if(([self.title length] == 0) || ([self.title isEqualToString:@"/"]))  {
        self.title = [_driver.url host];
    }
    
    if ([_driver isDownloadable]) {
//        _actionButton.enabled = YES;
    }
    
    if ([_urls count] > 1) {
        // Enable the Back button
        EntryLs *back = [[EntryLs alloc] initWithText:@".." IsDirectory:YES Date:nil Size:0];
        [_driver.listEntries insertObject:back atIndex:0];
        [back release];
    }
    
    [self.tableView reloadData];   
    _directoryListReceiving = NO;
    
    [self _receiveDidStopWithActivityIndicator:YES];
}


// =====================================================================================================
// --- directorySize -----------------------------------------------------------------------------------

- (void)getDirectorySize:(NSString *)dir {
    [self _receiveDidStartWithActivityIndicator:NO];
    
    [self performSelectorInBackground:@selector(_getDirectorySize:) withObject:dir];
}

- (void)_getDirectorySize:(NSString *)dir {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSNumber *result = [NSNumber numberWithInteger:0];
    @try {
        [_dirList removeAllObjects];
        BaseDriver *directoryDownloader = [_driver clone];
        directoryDownloader.url = [_driver.url URLByAppendingPathComponent:dir];
        directoryDownloader.delegate = self;
        result = [directoryDownloader directorySize];
        [_dirList addObjectsFromArray:directoryDownloader.listEntries];
    }
    @catch (NSException *exception) {        
    }
    @finally {
        [self performSelectorOnMainThread:@selector(directorySizeReceived:) withObject:result waitUntilDone:NO]; 
        [pool drain];        
    }
}

- (void)directorySizeReceived:(NSNumber *)value {
    [self _receiveDidStopWithActivityIndicator:NO];
    
    _totalBytesToReceive += [value unsignedLongLongValue];
    
    NSString *str = [NSString stringWithFormat:@"Are you about to download %.2fMb?", [value doubleValue]/(1024*1024)];
    
    _downloadDirectoryConfirmation = [[UIAlertView alloc] initWithTitle:@"Confirmation" message:str delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    
    [_downloadDirectoryConfirmation show];
}


// =====================================================================================================
// --- downloadFile ------------------------------------------------------------------------------------

- (void)downloadFile:(NSString *)filename WithSize:(NSNumber *)size {
    _fileDownloading = YES;
    [self _receiveDidStartWithActivityIndicator:NO];
    _totalBytesToReceive = [size unsignedLongLongValue];
    
    [self performSelectorInBackground:@selector(_downloadFile:) withObject:filename];
}

- (void)_downloadFile:(NSString *)filename {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    @try {
        [_fileDownloader downloadFileAsync:filename];
    }
    @catch (NSException *exception) {        
    }
    @finally { 
        [pool drain];        
    }
}

- (void)fileDownloaded:(NSString *)filepath {
    if([_driver isImageFile:filepath]) {
        [self showBrowser:[filepath lastPathComponent]];
    } else {
        [self showWebViewer:[[_driver pathToDownload] stringByAppendingPathComponent:[filepath lastPathComponent]]];
    }
    
    _fileDownloading = NO;
    [self _receiveDidStopWithActivityIndicator:NO];
}

- (void)stopFileDownloading {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    @try {
        if (_fileDownloader) {
            [_fileDownloader abort];
        }
    }
    @catch (NSException *exception) {        
        //
    }
    @finally { 
        [pool drain];        
    }
}

// -----------------------------------------------------------------------------------------------------

- (void)abortButtonPressed:(id)sender {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self performSelectorInBackground:@selector(stopFileDownloading) withObject:nil];
}


// -----------------------------------------------------------------------------------------------------
- (void)showBrowser:(NSString *)currentFilename {
    NSUInteger pageIndex = 0;
    NSUInteger i = 0;
    [_photos removeAllObjects];
    
    for (EntryLs *entry in _driver.listEntries) { 
        NSString *filename = [entry text];
        if([_driver isImageFile:filename]) {                
//            NSString *fileURL = [[_driver.url absoluteString] stringByAppendingString:[filename stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];

            if([filename isEqualToString:currentFilename]) pageIndex = i;
            
            //BaseDriver *downloadDriver = [_driver clone]; //[NSURL URLWithString:fileURL]];
            
            NSString *photoPath = [[_driver pathToDownload] stringByAppendingPathComponent:filename];
            MWPhoto *photo = [[MWPhoto alloc] initWithDriver:_driver PhotoPath:photoPath];
            photo.caption = filename;
            
            [_photos addObject:photo];
            [photo release];
            ++i;
        }
    }
    
    MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    [browser setInitialPageIndex:pageIndex];
    
    [self.navigationController pushViewController:browser animated:YES];
    // Release
    [browser release];
}

- (void)showWebViewer:(NSString *)filepath {
    
//    NSLog(@"%s [%@]", __PRETTY_FUNCTION__, filepath);
//    WebViewer *viewer = [[WebViewer alloc] init];
    UIDocumentInteractionController *viewer = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:filepath]];
    
    if (viewer) {
        viewer.delegate = self;
        [viewer retain];
    
//    viewer.url = [NSURL fileURLWithPath:filepath];
        BOOL success = [viewer presentPreviewAnimated:YES];
        if(!success) {
            if(!(success = [viewer presentOpenInMenuFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES])) {
                NSLog(@"VIEWER: FALSE");
                [viewer release];
            }
        }
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
        return _filteredListEntries.count;
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
    
    if (_directoryListReceiving) {
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
        cell.imageView.image = [UIImage imageNamed:@"Box.png"];
//        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        if (dateStr.length > 0) {
            cell.detailTextLabel.text = [NSString stringWithFormat:@"Modified: %@", dateStr];
        } else {
            cell.detailTextLabel.text = @"";
        }
//        label.text = @"";
    } else {
        cell.imageView.image = [UIImage imageNamed:@"Note.png"];
//        cell.accessoryType = UITableViewCellAccessoryNone;
        if (dateStr.length > 0) {
            cell.detailTextLabel.text = [NSString stringWithFormat:@"Modified: %@ Size: %@", dateStr, sizeStr];
        } else {
            cell.detailTextLabel.text = @"";
        }
//        label.text = sizeStr;
    }
  
    cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    

    /*
    UIButton *button = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    [button addTarget:self action:@selector(actionButtonPressed:) forControlEvents:UIControlEventTouchDown];
    [button setTitle:@"Action" forState:UIControlStateNormal];
    button.frame = CGRectMake(cell.frame.size.width - 32.0, 5.0, 30.0, cell.frame.size.height - 10.0);
    button.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [cell addSubview:button];
    */ 
    
//    [cell addSubview:label];
    

    return cell;
}


- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    if (_actionsSheet) {
        // Dismiss
        [_actionsSheet dismissWithClickedButtonIndex:_actionsSheet.cancelButtonIndex animated:YES];
    } else {
        EntryLs *entry = [_driver.listEntries objectAtIndex:indexPath.row];
        //UITableViewCell *owningCell = [self.tableView cellForRowAtIndexPath:indexPath];
        [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        
        // Sheet
        _actionsSheet = [[UIActionSheet alloc] init];
        _actionsSheet.delegate = self;
        if ([_driver isDownloadable]) {
            entry.isDir ? [_actionsSheet addButtonWithTitle:@"Download dir"] :
                          [_actionsSheet addButtonWithTitle:@"Download"];
        }
        else {
            entry.isDir ? [_actionsSheet addButtonWithTitle:@"Delete dir"] :
            [_actionsSheet addButtonWithTitle:@"Delete"];
            
            //            _actionsSheet.destructiveButtonIndex = 0;
        }
        
        [_actionsSheet addButtonWithTitle:@"Cancel"];
        [_actionsSheet setCancelButtonIndex:_actionsSheet.numberOfButtons-1];
        
        
        _actionsSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            [_actionsSheet showFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
        } else {
            [_actionsSheet showInView:[self.view window]];
        }            
    }

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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
    
    if (_directoryListReceiving) {
        return;
    }
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    
    EntryLs *entry = [_driver.listEntries objectAtIndex:indexPath.row];
    if(entry.isDir) {
        if ([cell.textLabel.text isEqualToString:@".."]) {
            // pop url
            [_urls removeObject:_driver.url];
            
            assert([_urls count] >= 1);
            _driver.url = [_urls objectAtIndex:[_urls count] - 1];
            [_driver changeDir:@".."];
        } else {
            _driver.url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@/", [_driver.url absoluteString], 
                                           [cell.textLabel.text stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
            [_driver changeDir:cell.textLabel.text];

            // Push url
            [_urls addObject:_driver.url];              
        }
        
        // move to new dir
        [self getDirectoryList];
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
            EntryLs *entry = [_driver.listEntries objectAtIndex:indexPath.row];

            NSString *filepath = [[_driver.url path] stringByAppendingPathComponent:cell.textLabel.text];
            [self downloadFile:filepath WithSize:[NSNumber numberWithLongLong:[entry size]]];
        }            
    }
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setToolbarHidden:YES animated:YES];
}

// UISearchBarDelegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    NSLog(@"%s", __PRETTY_FUNCTION__);
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
        [self getDirectoryList];
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
    if (alertView == _downloadDirectoryConfirmation) {
        if (buttonIndex == 0) {
            [_dirList removeAllObjects];

        } else if (buttonIndex == 1) {
            for (EntryLs *entry in _dirList) {
                [_downloads addEntry:entry]; //:[path stringByAppendingPathComponent:entry]];
            }
            
            // refresh "Downloads" badge
            [_downloads refreshBadge];
        }
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
    [alertView release];
}


#pragma mark - LoadingDelegate

// -----------------------------------------------------------------------------------------------------

- (void)driver:(BaseDriver *)driver handleLoadingDidEndNotification:(id)object {
    if (driver == _driver) {
        if ((NSString *)object == @"DIRECTORY_LIST_RECEIVED") {
            [self directoryListReceived];
        }
    }
    else if (driver == _fileDownloader) {
        [self fileDownloaded:(NSString *)object];
    }
}

- (void)driver:(BaseDriver *)driver handleLoadingProgressNotification:(id)object {
    // Notification from _directoryDownloader
    if (driver == _fileDownloader) {
        NSLog(@"%s [%llu]", __PRETTY_FUNCTION__, [(NSNumber *)object unsignedLongLongValue]);
        _bytesReceived = [(NSNumber *)object unsignedLongLongValue];
    }
    
    _progressView.progress = (double)_bytesReceived / (double)_totalBytesToReceive;
}

- (void)driver:(BaseDriver *)driver handleAbortedNotification:(id)object {
    if (driver == _fileDownloader) {
        _fileDownloading = NO;
        [self _receiveDidStopWithActivityIndicator:NO];
    }
}

- (void)driver:(BaseDriver *)driver handleErrorNotification:(id)object {
    NSString *errorMessage = @"";
    if (driver == _driver) {
        [self _receiveDidStopWithActivityIndicator:YES];
        errorMessage = (NSString *)object;
    } 
    else if (driver == _fileDownloader) {
        errorMessage = (NSString *)object;
        _fileDownloading = NO;
    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:errorMessage delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    [alert show];
}

#pragma mark - Action Sheet Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (actionSheet == _actionsSheet) {           
        // Actions 
        NSLog(@"%s [index=%d]", __PRETTY_FUNCTION__, buttonIndex);
        if (buttonIndex != actionSheet.cancelButtonIndex) {
            
            if (buttonIndex == actionSheet.destructiveButtonIndex) {
                [[NSFileManager defaultManager] removeItemAtPath:[_driver pathToDownload] error:nil];
                [self getDirectoryList];
            }
            
            if (buttonIndex == 0) { 
                // Start/Stop direcory downloading
                
                NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
                UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                
                if ([_driver isDownloadable]) {
                    if (cell.accessoryType == UITableViewCellAccessoryNone) {
                        NSLog(@"Download file %@", cell.textLabel.text);
                        
                        EntryLs *origEntry = [_driver.listEntries objectAtIndex:indexPath.row];
                        NSString *filepath = [[_driver.url path] stringByAppendingPathComponent:cell.textLabel.text];
                        
                        EntryLs *entry = [[EntryLs alloc] initWithText:filepath IsDirectory:NO Date:origEntry.date
                                                                  Size:origEntry.size];
                        [_downloads addEntry:entry];
                        [_downloads refreshBadge];
                    } else {
                        [self getDirectorySize:[cell.textLabel.text isEqualToString:@".."] ? @"" : cell.textLabel.text];
                    }
                }
                else {
                    if (cell.accessoryType == UITableViewCellAccessoryNone) {
                        NSLog(@"Delete file file %@", cell.textLabel.text);
                    }
                    else {
                        NSLog(@"Delete dir %@", cell.textLabel.text);
                    }
                    
                    //            _actionsSheet.destructiveButtonIndex = 0;
                }

                
//                if (!_directoryDownloading) {
//                    [self getDirectorySize];
//                } else {
//                    [self performSelectorInBackground:@selector(stopDirectoryDownloading) withObject:nil];
//                }
//                return;
            } else if (buttonIndex == (actionSheet.firstOtherButtonIndex + 1)) {
//                return;	
            }
        }
        //[actionSheet release];
        [_actionsSheet release];
        _actionsSheet = nil;
    }
}

// 
- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return _photos.count;
}

- (id<MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    return [_photos objectAtIndex:index];
}


@end

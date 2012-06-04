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
#import "BaseDriver.h"
#import "EntryLs.h"

#define REFRESH_HEADER_HEIGHT 52.0f

@interface DirectoryList () {
    BaseDriver *_driver;
    
    // ProgressView 
    UIProgressView *_progressView;
//    double _totalFilesSize;
//    double _downloadedFilesSize;
    
    // Toolbar
    UIBarButtonItem *_actionButton;
    UIActionSheet *_actionsSheet;
    
    // URLs Stack
    NSMutableArray *_urls;
    
    NSMutableArray *_filteredListEntries;
    IBOutlet UISearchBar *_searchBar;
    BOOL _searching;
    BOOL _letUserSelectRow;
    
    BaseDriver *_directoryDownloader;
//    BaseDownloader *_fileDownloader;
        
    UIActivityIndicatorView *_activityIndicator;
}

- (void)searchTableView;
- (void)doneSearching_Clicked:(id)sender;

@end

@implementation DirectoryList

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
    }
    return self;
}

- (void)dealloc {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self _receiveDidStop];
    
    [_driver release];
    
//    [_buttons release];
    [_actionButton release];
    
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
//    UIBarButtonItem *sortButton = [[UIBarButtonItem alloc] initWithTitle:@"Sort" style:UIBarButtonItemStyleBordered 
//                                                                  target:self action:@selector(sortButton_Clicked:)];
    _actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction 
                                                      target:self action:@selector(actionButtonPressed:)];
    self.navigationItem.rightBarButtonItem =_actionButton;
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
    
    [_driver performSelectorInBackground:@selector(directoryList) withObject:nil];
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

- (void)handleLoadingProgressNotification:(double)value {
    // Notification from DirectoryDownloader or BaseDownloader
    _progressView.progress = value;
}

- (void)handleLoadingDidEndNotification:(id)sender {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, sender);
    
    if([[sender class] isSubclassOfClass:[BaseDriver class]]) {
        // Notification from BaseLs

        self.title = [_driver.url lastPathComponent];
        if(([self.title length] == 0) || ([self.title isEqualToString:@"/"]))  {
            self.title = [_driver.url host];
        }
        
        if ([_driver isDownloadable]) {
            _actionButton.enabled = YES;
        }
        
        if ([_urls count] > 1) {
            // Enable the Back button
            EntryLs *back = [[EntryLs alloc] initWithText:@".." IsDirectory:YES Date:nil Size:0];
            [_driver.listEntries insertObject:back atIndex:0];
            [back release];
        }
        
        [self.tableView reloadData];    
        [self _receiveDidStop];
    } /*
       else if([[sender class] isSubclassOfClass:[BaseDownloader class]]){
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
    */
}

- (void)handleDirectoryLoadingDidEndNotification {
    NSLog(@"Directory downloaded!!");
    
    if (_directoryDownloader) {
        [_directoryDownloader release];
        _directoryDownloader = nil;
    }
    
    _actionButton.enabled = YES;
    self.navigationItem.titleView = nil;
    [self.navigationItem setHidesBackButton:NO animated:NO];
}


- (void)actionButtonPressed:(id)sender {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    if (_actionsSheet) {
        // Dismiss
        [_actionsSheet dismissWithClickedButtonIndex:_actionsSheet.cancelButtonIndex animated:YES];
    } else {
        // Sheet
        _actionsSheet = [[[UIActionSheet alloc] initWithTitle:nil delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil
                                                    otherButtonTitles:NSLocalizedString(@"Download", nil), /*NSLocalizedString(@"Copy", nil),*/ nil] autorelease];
            
        _actionsSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            [_actionsSheet showFromBarButtonItem:sender animated:YES];
        } else {
            [_actionsSheet showInView:self.view];
        }            
    }
}

- (void)downloadDirectory:(BOOL)recursive {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    if (![_driver isDownloadable]) {
        return;
    }
    
    _directoryDownloader = [[_driver clone] retain];
    _directoryDownloader.delegate = self;
    
    [_directoryDownloader downloadDirectory];
}

- (void)showBrowser:(NSString *)currentFilename {
    NSUInteger pageIndex = 0;
    NSUInteger i = 0;
    NSMutableArray *photos = [[NSMutableArray alloc] init];
    for (EntryLs *entry in _driver.listEntries) { 
        NSString *filename = [entry text];
        if([_driver isImageFile:filename]) {                
//            NSString *fileURL = [[_driver.url absoluteString] stringByAppendingString:[filename stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];

            if([filename isEqualToString:currentFilename]) pageIndex = i;
            
            //BaseDriver *downloadDriver = [_driver clone]; //[NSURL URLWithString:fileURL]];
            
            NSString *photoPath = [[_driver pathToDownload] stringByAppendingPathComponent:filename];
            Photo *photo = [[Photo alloc] initWithDriver:_driver PhotoPath:photoPath];
            photo.caption = filename;
            
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
    
    if (viewer) {
        viewer.delegate = self;
        [viewer retain];
    
//    viewer.url = [NSURL fileURLWithPath:filepath];
        BOOL success = [viewer presentPreviewAnimated:YES];
        if(!success) {
            NSLog(@"VIEWER: FALSE");
            [viewer release];
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
        if (dateStr.length > 0) {
            cell.detailTextLabel.text = [NSString stringWithFormat:@"Modified: %@", dateStr];
        } else {
            cell.detailTextLabel.text = @"";
        }
//        label.text = @"";
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
        if (dateStr.length > 0) {
            cell.detailTextLabel.text = [NSString stringWithFormat:@"Modified: %@ Size: %@", dateStr, sizeStr];
        } else {
            cell.detailTextLabel.text = @"";
        }
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
        if ([cell.textLabel.text isEqualToString:@".."]) {
            // Pop url
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
            
            [self showBrowser:cell.textLabel.text];
        
            /*
            NSString *fileURL = [[_driver.url absoluteString] stringByAppendingString:[cell.textLabel.text stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            _fileDownloader = [[_driver createDownloaderDriverWithURL:[NSURL URLWithString:fileURL]] retain];
            _fileDownloader.delegate = self;
            
            EntryLs *entry = [_driver.listEntries objectAtIndex:indexPath.row];
            _fileDownloader.totalFileSize = [entry size];
                
            self.navigationItem.titleView = _progressView;
            [self.navigationItem setHidesBackButton:YES animated:YES];
        
            [_fileDownloader startReceive];
             */
        }            
    }
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setToolbarHidden:YES animated:YES];
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
    self.navigationItem.rightBarButtonItem = _actionButton;
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


#pragma mark - Action Sheet Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (actionSheet == _actionsSheet) {           
        // Actions 
        _actionsSheet = nil;
        if (buttonIndex != actionSheet.cancelButtonIndex) {
            if (buttonIndex == actionSheet.firstOtherButtonIndex) {
                [self downloadDirectory:YES];
                return;
            } else if (buttonIndex == actionSheet.firstOtherButtonIndex + 1) {
                return;	
            }
        }
    }
}

@end

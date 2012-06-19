//
//  Downloads.m
//  PhotoBrowser
//
//  Created by ukv on 6/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Downloads.h"
#import "BaseDriver.h"
#import "EntryLs.h"

@interface Downloads ()

@end

@implementation Downloads

@synthesize driver = _driver;
@synthesize isLoadingInProgress = _isLoadingInProgress;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        self.tabBarItem = [[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemDownloads tag:2];
        
        // ProgressView
        _progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 20.0)];
        _progressView.progressViewStyle = UIProgressViewStyleBar;
        
        _entries = [[NSMutableArray alloc] init];
        _isLoadingInProgress = NO;
        _isDirty = NO;
        
    }
    return self;
}

- (void)setDriver:(BaseDriver *)driver {
    if (_driver != driver) {
        [_driver release];
        _driver = [driver retain];
        _driver.delegate = self;
    }
}

/*
- (void)loadView {
    [super loadView];
    
    //    self.view.backgroundColor = [[UIColor alloc] initWithPatternImage:[UIImage imageNamed:@"ravenna.png"]];
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPause
                                                                                           target:self action:@selector(pauseButtonPressed:)] autorelease];
}
*/

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = @"Downloads";
    
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
    [_progressView release], _progressView = nil;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.navigationController setToolbarHidden:YES animated:YES];
    
    if (_isDirty) {
        [self.tableView reloadData];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return _entries.count;
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
        // cell.showsReorderControl = YES;
    }
    
    EntryLs *listEntry = [_entries objectAtIndex:indexPath.row];
    
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
    
    cell.textLabel.text = [[listEntry text] lastPathComponent];
    
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
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ Size: %@", 
                                     [[listEntry text] stringByDeletingLastPathComponent], sizeStr];

        //        label.text = sizeStr;
    }    
    
//    NSString *filepath = [entry text];
//    cell.textLabel.text = [filepath lastPathComponent];
//    cell.detailTextLabel.text = [filepath stringByDeletingLastPathComponent];
    
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

- (void)addEntry:(EntryLs *)entry {
    [_entries addObject:entry];
    _totalBytesToReceive += entry.size;
    _isDirty = YES;
}

- (void)refreshBadge {
    self.tabBarItem.badgeValue = _entries.count ? [NSString stringWithFormat:@"%d", _entries.count] : nil;
    
    if (!_isLoadingInProgress) {
        [self start];
    }
}

- (void)start {
    if (_entries.count > 0) {
        NSString *filepath = [[_entries objectAtIndex:0] text];
        
        if (!_isLoadingInProgress) {
            self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPause
                                                                                                   target:self action:@selector(pauseButtonPressed:)] autorelease];
            self.navigationItem.titleView = _progressView;
            _isLoadingInProgress = YES;
            
            _totalBytesReceived = 0;
        }
        
        [self performSelectorInBackground:@selector(_downloadFile:) withObject:filepath];
    }
}

- (void)_downloadFile:(NSString *)filename {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    @try {
        [_driver downloadFileAsync:filename];
    }
    @catch (NSException *exception) {        
    }
    @finally { 
        [pool drain];        
    }
}


- (IBAction)pauseButtonPressed:(id)sender {
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay
                                                        target:self action:@selector(playButtonPressed:)] autorelease];
    [_driver abort];
    
}

- (IBAction)playButtonPressed:(id)sender {
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPause
                                                        target:self action:@selector(pauseButtonPressed:)] autorelease];
    [self start];
    
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     [detailViewController release];
     */
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    EntryLs *entry = [[_entries objectAtIndex:sourceIndexPath.row] retain];
    [_entries removeObject:entry];
    [_entries insertObject:entry atIndex:destinationIndexPath.row];
    [entry release];
}

#pragma mark - Loading delegate

- (void)driver:(BaseDriver *)driver handleLoadingDidEndNotification:(id)object {
    if (_driver == driver) {
        EntryLs *downloadedEntry = [_entries objectAtIndex:0];
        assert([downloadedEntry.text isEqualToString:(NSString *)object]);
        
        _totalBytesReceived += downloadedEntry.size;
        [_entries removeObject:downloadedEntry];
        
        [self.tableView reloadData];
        [self refreshBadge];
        if (_entries.count > 0) {
            [self start];
        } else {
            _isLoadingInProgress = NO;
            self.navigationItem.leftBarButtonItem = nil;
            self.navigationItem.titleView = nil;
            _totalBytesToReceive = 0;
            _totalBytesReceived = 0;
            NSLog(@"STOP: ALL FILES DOWNLOADED");
        }
    }
}

- (void)driver:(BaseDriver *)driver handleLoadingProgressNotification:(id)object {
    if (driver == _driver) {
        _bytesReceived = [(NSNumber *)object unsignedLongLongValue];
    }
    
    _progressView.progress = (double)(_bytesReceived + _totalBytesReceived) / (double)_totalBytesToReceive;
}

- (void)driver:(BaseDriver *)driver handleAbortedNotification:(id)object {
    /*
    if (sender == _directoryDownloader) {
        // release
        [_directoryDownloader release];
        _directoryDownloader = nil;
        
        _directoryDownloading = NO;
        self.navigationItem.titleView = nil;
        [self _receiveDidStopWithActivityIndicator:NO];
    } else if (sender == _fileDownloader) {
        // release
        [_fileDownloader release];
        _fileDownloader = nil;
        
        _fileDownloading = NO;
        self.navigationItem.titleView = nil;
        [self _receiveDidStopWithActivityIndicator:NO];
        //        self.navigationItem.rightBarButtonItem =_actionButton;
    }
    */ 
}

- (void)driver:(BaseDriver *)driver handleErrorNotification:(id)object {
    NSString *errorMessage = @"";
    if (driver == _driver) {
        //[self _receiveDidStopWithActivityIndicator:YES];
        errorMessage = (NSString *)object;
    } 
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:errorMessage delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    [alert show];
}


@end

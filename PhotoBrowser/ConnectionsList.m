//
//  ConnectionsList.m
//  PhotoBrowser
//
//  Created by ukv on 5/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ConnectionsList.h"
#import "LoginPreferences.h"
#import "FtpDriver.h"
#import "DirectoryList.h"
#import "Downloads.h"
#import "Reachability.h"

@interface ConnectionsList () {
    NSMutableArray *_listEntries;
    NSMutableDictionary *_dictionary;
}

- (void)reload;

@end

@implementation ConnectionsList;


- (id)initWithDownloads:(Downloads *)downloads
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        // Custom initialization   
        self.tabBarItem = [[[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemContacts tag:0] autorelease];
        
        _downloads = downloads;
        _listEntries = [[NSMutableArray alloc] init];
        _isDirty = YES;
    }
    return self;
}

- (void)dealloc {
    NSLog(@"%s", __PRETTY_FUNCTION__);

    [_listEntries release];
    [_dictionary release];
    [super dealloc];
}

- (void)loadView {
    [super loadView];
    
//    self.view.backgroundColor = [[UIColor alloc] initWithPatternImage:[UIImage imageNamed:@"ravenna.png"]];
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                           target:self action:@selector(addButtonPressed:)] autorelease];
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                                                            target:self action:@selector(startEditing)] autorelease];
    
//    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc] 
//                                          initWithTarget:self action:@selector(handleLongPress:)];
//    lpgr.delegate = self;
//    [self.tableView addGestureRecognizer:lpgr];
//    [lpgr release];

//    self.tableView.editing = YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    
    _internetReach = [[Reachability reachabilityForInternetConnection] retain];
    [_internetReach startNotifier];
    
    [self updateInternetStatus:_internetReach];

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
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.navigationController setToolbarHidden:YES animated:YES];
    
    if (_isDirty) {
        [self reload];
        [self.tableView reloadData];
    }
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}


// --------------
- (NSString *)connectionsFilePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *result = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"connections.plist"]; 
    
    return result;
}

- (void)needToRefresh {
    _isDirty = YES;
}

- (void)reload {
    if (_dictionary) [_dictionary release];
    [_listEntries removeAllObjects];
    
    _dictionary = [[NSMutableDictionary alloc] initWithContentsOfFile:[self connectionsFilePath]];
    if (_dictionary) {
        for (id key in _dictionary) {
            [_listEntries addObject:key];
        }
    }
    _isDirty = NO;
}

// --------------
- (IBAction)addButtonPressed:(id)sender {
    //
    LoginPreferences *login = [[LoginPreferences alloc] init];
    login.delegate = self;
    
    // Pass the selected object to the new view controller.
    [self.navigationController pushViewController:login animated:YES];
    [login release];

}

- (void)startEditing {
    [self.tableView setEditing:YES animated:YES];
    
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                        target:self action:@selector(stopEditing)] autorelease];
}

- (void)stopEditing {
    [self.tableView setEditing:NO animated:YES];
    
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                                        target:self action:@selector(startEditing)] autorelease];
}


// --------------
#pragma mark - Table view data source

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
    
    cell.textLabel.text = [_listEntries objectAtIndex:indexPath.row];
    cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    
    return cell;
}


- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    NSString *url = [_listEntries objectAtIndex:indexPath.row];
//    NSDictionary *entry = [_dictionary objectForKey:url];
    
    // Pass the selected object to the new view controller.
    
    LoginPreferences *lp = [[LoginPreferences alloc] init];
    lp.delegate = self;
    [lp setAttributes:url];
    [self.navigationController pushViewController:lp animated:YES];
    [lp release];
}


// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}



// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle 
forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        [_listEntries removeObjectAtIndex:indexPath.row];
        
        [_dictionary removeObjectForKey:cell.textLabel.text];
        [_dictionary writeToFile:[self connectionsFilePath] atomically:YES];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
    }   
//    else if (editingStyle == UITableViewCellEditingStyleInsert) {
//        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
//    }   
}


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
    // Navigation logic may go here. Create and push another view controller.
    NSString *alias = [_listEntries objectAtIndex:indexPath.row];
    NSDictionary *entry = [_dictionary objectForKey:alias];
    
    NSString *urlStr = [entry objectForKey:@"url"];
    // add last "/"
    if ([urlStr characterAtIndex:urlStr.length - 1] != '/') {
        urlStr = [urlStr stringByAppendingString:@"/"];
    }
    
    BOOL success = NO;
    NSString *errorStr;
    
    NSURL *url = [NSURL URLWithString:urlStr];
    // check url
    if (url && url.scheme && url.host) {
        if ([url.scheme isEqualToString:@"ftp"] || [url.scheme isEqualToString:@"ftps"]) {
            success = YES;
            FtpDriver *ftpDriver = [[FtpDriver alloc] initWithURL:url];
            ftpDriver.username = [entry objectForKey:@"username"];
            ftpDriver.password = [entry objectForKey:@"password"];

            ftpDriver.port = [NSNumber numberWithInteger:[[entry objectForKey:@"port"] integerValue]];
            ftpDriver.passiveMode = [[entry objectForKey:@"connectionType"] boolValue];
            ftpDriver.cacheMode = [[entry objectForKey:@"cacheMode"] boolValue];
            ftpDriver.encoding = [entry objectForKey:@"encoding"];
            
            DirectoryList *dirList = [[DirectoryList alloc] initWithDriver:ftpDriver];
            _downloads.driver = [ftpDriver clone];
            dirList.downloads = _downloads;
            
            [ftpDriver release];
            [self.navigationController pushViewController:dirList animated:YES];
            // Release
            [dirList release];
        } else {
            errorStr = [NSString stringWithFormat:@"Unknown protocol: %@", url.scheme];
        }
    } else {
        errorStr = @"Invalid URL";
    }

    if (!success) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:errorStr delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alert show];
    }
}

// UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [alertView release];
}


//
- (void)updateInternetStatus:(Reachability *)curReach {
    NetworkStatus netStatus = [curReach currentReachabilityStatus];
    NSString *statusString = @"Network: ";
    
    switch (netStatus) {
        case NotReachable:
            statusString = [statusString stringByAppendingString:@"Not Available"];
            break;
        case ReachableViaWWAN:
            statusString = [statusString stringByAppendingString:statusString = @"WWAN"];
            break;
        case ReachableViaWiFi:
            statusString = [statusString stringByAppendingString:statusString = @"WiFi"];
            break;
        default:
            break;
    }
    
    self.navigationItem.title = statusString;
}

- (void)reachabilityChanged:(NSNotification *)note {
    Reachability *curReach = [note object];
    //NSParameterAssert([curReach isKindOfClass:[Reachability class]]);
    [self updateInternetStatus:curReach];
}


@end

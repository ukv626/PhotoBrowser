//
//  LoginPreferences.m
//  PhotoBrowser
//
//  Created by ukv on 6/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LoginPreferences.h"
#import "ConnectionsList.h"

@interface LoginPreferences () {
    
}

@property (nonatomic, retain) NSDictionary *entry;

- (IBAction)segementControlValueChanged:(id)sender;

@end

@implementation LoginPreferences

@synthesize delegate = _delegate;
@synthesize entry = _entry;

- (id)init {
    if ((self = [super initWithStyle:UITableViewStyleGrouped])) {
        //
        _connectionTypes = [[NSArray alloc] initWithObjects:@"FTP",@"FTPS", nil];
    }
    
    return self;
}

- (void)dealloc {
    [_connectionTypes release];
    
    [_alias release];
    [_server release];
    [_port release];
    [_protocol release];
    [_connectionType release];
    
    [_username release];
    [_password release];
    
    [_cacheMode release];
    
    [_entry release];
    
    [super dealloc];
}


- (void)loadView {
    [super loadView];
    
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(saveButtonClicked:)] autorelease];
}


- (void)viewDidLoad
{
    [super viewDidLoad];

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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return SECTIONS_COUNT;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    switch (section) {
        case connectionSection:
            return 5;
            break;
        case loginSection:
            return 2;
            break;
        case otherSection:
            return 1;
            break;
        default:
            break;
    }
    
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case connectionSection:
            return @"Connections Settings";
            break;
        case loginSection:
            return @"Login Settings";
            break;
        case otherSection:
            return @"Other Settings";
            break;
        default:
            break;
    }
    
    return nil;
}

- (CGFloat)cellsMargin {
    // No margins for plain table views
    if (self.tableView.style == UITableViewStylePlain) {
        return 0;
    }
    
    // iPhone always have 10 pixels margin
    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
        return 10;
    }
    
    CGFloat tableWidth = self.tableView.frame.size.width;
    
    // Really small table
    if (tableWidth <= 20) {
        return tableWidth - 10;
    }
    
    // Average table size
    if (tableWidth < 400) {
        return 10;
    }
    
    // Big tables have complex margin's logic
    // Around 6% of table width,
    // 31 <= tableWidth * 0.06 <= 45
    
    CGFloat marginWidth  = tableWidth * 0.06;
    marginWidth = MAX(31, MIN(45, marginWidth));
    return marginWidth;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *CellIdentifier = [NSString stringWithFormat:@"%d:%d", indexPath.section, indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell...
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        CGSize cellSize = cell.frame.size;
        float cellMargin = [self cellsMargin];
//        float cellWidth = tableView.frame.size.width - [self cellsMargin] * 2;
//        NSLog(@"cellWidth=%f", cellWidth);
        
        switch (indexPath.section) {
            case connectionSection:
                switch (indexPath.row) {
                    case 0:
                        _alias = [[UITextField alloc] initWithFrame:CGRectMake(cellSize.width - 190, 8, 
                                                                                190-cellMargin-10, cellSize.height-16)];
                        _alias.autoresizingMask = UIViewAutoresizingFlexibleWidth;
                        _alias.delegate = self;
                        _alias.borderStyle = UITextBorderStyleRoundedRect;
                        _alias.clearButtonMode = UITextFieldViewModeWhileEditing;
//                        _alias.keyboardType = UIKeyboardTypeURL;
                        _alias.returnKeyType = UIReturnKeyDone;
//                        _alias.placeholder = @"";
                        [cell addSubview:_alias];
                        
                        if (_entry) _alias.text = [_entry objectForKey:@"alias"];
                        cell.textLabel.text = @"Alias";
                        break;
                    case 1:
                        _server = [[UITextField alloc] initWithFrame:CGRectMake(cellSize.width-190, 8, 
                                                                                 190-cellMargin-10, cellSize.height-16)];
                        _server.autoresizingMask = UIViewAutoresizingFlexibleWidth;
                        _server.delegate = self;
                        _server.borderStyle = UITextBorderStyleRoundedRect;
                        _server.clearButtonMode = UITextFieldViewModeWhileEditing;
                        _server.keyboardType = UIKeyboardTypeURL;
                        _server.returnKeyType = UIReturnKeyDone;
                        _server.placeholder = @"server[/path]";
                        _server.autocapitalizationType = UITextAutocapitalizationTypeNone;
                        [cell addSubview:_server];
                        
                        if (_entry) _server.text = [_entry objectForKey:@"server"];
                        cell.textLabel.text = @"Server";
                        break;
                    case 2:
                        _port = [[UITextField alloc] initWithFrame:CGRectMake(cellSize.width-110, 8, 
                                                                               110-cellMargin-10, cellSize.height - 16)];
                        _port.autoresizingMask = UIViewAutoresizingFlexibleWidth;
                        _port.delegate = self;
                        _port.borderStyle = UITextBorderStyleRoundedRect;
                        _port.clearButtonMode = UITextFieldViewModeWhileEditing;
                        _port.textAlignment = UITextAlignmentRight;
                        //_port.keyboardType = UIKeyboardTypeNumberPad;
                        _port.returnKeyType = UIReturnKeyDone;
                        
                        _port.text = _entry ? [_entry objectForKey:@"port"] : @"21";
                        [cell addSubview:_port];
                        cell.textLabel.text = @"Port";
                        break;
                    case 3:
                        _protocol = [[UISegmentedControl alloc] initWithItems:_connectionTypes];
                        _protocol.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
                        _protocol.frame = CGRectMake(cellSize.width - 135 - cellMargin, 8, 
                                                     145-20, cellSize.height - 16);
                        _protocol.selectedSegmentIndex = 0;
                        [_protocol addTarget:self action:@selector(segementControlValueChanged:) forControlEvents:UIControlEventValueChanged];
                        [cell addSubview:_protocol];
                        
                        if (_entry) {
                            NSNumber *protocol = [_entry objectForKey:@"protocol"];
                            _protocol.selectedSegmentIndex = [protocol integerValue];
                        }
                        cell.textLabel.text = @"Protocol";
                        break;
                    case 4:
                        _connectionType = [[UISwitch alloc] initWithFrame:CGRectMake(cellSize.width-90-cellMargin, 8, 
                                                                            100, cellSize.height - 16)];
                        _connectionType.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
                        _connectionType.on = YES;
                        [cell addSubview:_connectionType];
                        
                        if (_entry) {
                            NSNumber *connectionType = [_entry objectForKey:@"connectionType"];
                            _connectionType.on = [connectionType boolValue];
                        }
                        cell.textLabel.text = @"Passive mode";
                        break;
                }
                break;
                
            case loginSection:
                switch (indexPath.row) {
                    case 0:
                        _username = [[UITextField alloc] initWithFrame:CGRectMake(cellSize.width-190, 8, 
                                                                    190-cellMargin-10, cellSize.height - 16)];
                        _username.autoresizingMask = UIViewAutoresizingFlexibleWidth;
                        _username.delegate = self;
                        _username.borderStyle = UITextBorderStyleRoundedRect;
                        _username.placeholder = @"Username";
                        _username.clearButtonMode = UITextFieldViewModeWhileEditing;
                        _username.autocapitalizationType = UITextAutocapitalizationTypeNone;
                        [cell addSubview:_username];
                        
                        if (_entry) _username.text = [_entry objectForKey:@"username"];
                        cell.textLabel.text = @"Login";
                        break;
                    case 1:
                        _password = [[UITextField alloc] initWithFrame:CGRectMake(cellSize.width-190, 8, 
                                                                                  190-cellMargin-10, cellSize.height - 16)];
                        _password.autoresizingMask = UIViewAutoresizingFlexibleWidth;
                        _password.delegate = self;
                        _password.borderStyle = UITextBorderStyleRoundedRect;
                        _password.placeholder = @"Password";
                        _password.clearButtonMode = UITextFieldViewModeWhileEditing;
                        _password.secureTextEntry = YES;
                        [cell addSubview:_password];
                        
                        if (_entry) _password.text = [_entry objectForKey:@"password"];
                        cell.textLabel.text = @"Password";
                        break;
                }
                break;
                
            case otherSection:
                switch (indexPath.row) {
                    case 0:
                        _cacheMode = [[UISwitch alloc] initWithFrame:CGRectMake(cellSize.width-90-cellMargin, 8, 
                                                                        100, cellSize.height - 16)];
                        _cacheMode.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
                        _cacheMode.on = YES;
                        [cell addSubview:_cacheMode];
                        
                        if (_entry) {
                            NSNumber *cacheMode = [_entry objectForKey:@"cacheMode"];
                            _cacheMode.on = [cacheMode boolValue];
                        }
                        cell.textLabel.text = @"Save cache";
                        break;

                }
                break;
        }
        
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
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     [detailViewController release];
     */
}

#pragma mark - UITextField delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if ((textField == _alias) ||
        (textField == _server) || 
        (textField == _port) || 
        (textField == _username) ||
        (textField == _password) ) {
        [textField resignFirstResponder];
    }
    
    return NO;
}


- (void)saveButtonClicked:(id)sender {
    BOOL success = NO;
    NSString *errorStr = @"";
    NSString *scheme = [[[_connectionTypes objectAtIndex:_protocol.selectedSegmentIndex] stringByAppendingString:@"://"] lowercaseString];

    NSString *urlStr = [scheme stringByAppendingString:_server.text];
    
    NSURL *url = [NSURL URLWithString:urlStr];
    // check url
    if (url && url.scheme && url.host) {
        if ([url.scheme isEqualToString:@"ftp"] || [url.scheme isEqualToString:@"ftps"]) {
            
            if (_alias.text.length == 0) _alias.text = urlStr;
            
            // add last "/"
            if ([urlStr characterAtIndex:urlStr.length - 1] != '/') {
                urlStr = [urlStr stringByAppendingString:@"/"];
            }
                
            NSString *filepath = [_delegate connectionsFilePath];
            NSMutableDictionary *dictionary;
            dictionary = [[NSMutableDictionary alloc] initWithContentsOfFile:filepath];
            if (!dictionary) {
                dictionary = [[NSMutableDictionary alloc] init];
            }
            
            // TODO: check if emtpy fields
            NSDictionary *innerDict = [dictionary objectForKey:_alias.text];
            if (innerDict) {
                [innerDict setValue:urlStr forKey:@"url"];
                [innerDict setValue:_server.text forKey:@"server"];
                [innerDict setValue:_port.text forKey:@"port"];
                [innerDict setValue:[NSNumber numberWithInteger:_protocol.selectedSegmentIndex] forKey:@"protocol"];
                [innerDict setValue:[NSNumber numberWithBool:_connectionType.on] forKey:@"connectionType"];
                [innerDict setValue:_username.text forKey:@"username"];
                [innerDict setValue:_password.text forKey:@"password"];
                [innerDict setValue:[NSNumber numberWithBool:_cacheMode.on] forKey:@"cacheMode"];
            } else {
                innerDict = [NSDictionary dictionaryWithObjects:
                             [NSArray arrayWithObjects:
                              urlStr,
                              _server.text,
                              _port.text,
                              [NSNumber numberWithInteger:_protocol.selectedSegmentIndex],
                              [NSNumber numberWithBool:_connectionType.on],
                              _username.text,
                              _password.text, 
                              [NSNumber numberWithBool:_cacheMode.on], nil] 
                                                        forKeys:[NSArray arrayWithObjects:@"url", @"server", @"port", @"protocol", @"connectionType", @"username", @"password",  @"cacheMode", nil]];
            }
            [dictionary setObject:innerDict forKey:_alias.text];
            success = [dictionary writeToFile:filepath atomically:YES];
            [dictionary release];
        } else {
            errorStr = [NSString stringWithFormat:@"Unknown protocol: %@", url.scheme];
        }
    } else {
        errorStr = @"Invalid URL";
    }
    
    if (success) {
        [_delegate needToRefresh];
        [self.navigationController popViewControllerAnimated:YES];
    }else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:errorStr delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alert show];
    }
}

- (void)setAttributes:(NSString *)alias {
    NSString *filepath = [_delegate connectionsFilePath];
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] initWithContentsOfFile:filepath];
    if (!dictionary) {
        return;
    }
    
    NSDictionary *innerDict = [dictionary objectForKey:alias];

    if (innerDict) {
        self.entry = innerDict;
        [self.entry setValue:alias forKey:@"alias"];
    }
    
    [dictionary release];
}

- (IBAction)segementControlValueChanged:(id)sender {
    if (sender == _protocol) {
        _port.text =  (_protocol.selectedSegmentIndex == 0) ? @"21" : @"443";
    }
}

@end

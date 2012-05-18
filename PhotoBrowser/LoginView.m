//
//  LoginView.m
//  PhotoBrowser
//
//  Created by ukv on 5/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LoginView.h"
#import "Browser.h"
//#import "Photo.h"
#import "DirectoryList.h"
#import "LocalLs.h"
#import "FtpLs.h"


@interface LoginView () {
    // Toolbar
    NSMutableArray *_buttons;
}

// Private methods
//- (CGRect)frameForMainView;
@end

@implementation LoginView


- (IBAction)localButton_Clicked:(id)sender {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *dir = [[paths objectAtIndex:0] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]; //[NSString stringWithFormat:@"/Downloads/ukv"];

    LocalLs *localLs = [[LocalLs alloc] initWithURL:[NSURL URLWithString:dir]];

    DirectoryList *dirList = [[DirectoryList alloc] initWithDriver:localLs];
    
    [localLs release];
    [self.navigationController pushViewController:dirList animated:YES];
    
    // Release
    [dirList release];
}


- (IBAction)connectButton_Clicked:(id)sender {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    FtpLs *ftpLs = [[FtpLs alloc] initWithURL:[NSURL URLWithString:self.urlText.text]];
    ftpLs.username = self.usernameText.text;
    ftpLs.password = self.passwordText.text;
    
    DirectoryList *dirList = [[DirectoryList alloc] initWithDriver:ftpLs];
    
    [ftpLs release];
    [self.navigationController pushViewController:dirList animated:YES];
    
    // Release
    [dirList release];
}

/*
- (void)textFieldDidEndEditing:(UITextField *)textField {
    NSString *defaultsKey;
    NSString *newValue;
    NSString *oldValue;
    
    if(textField == self.urlText) {
        defaultsKey =@"URLText";
    } else if(textField == self.usernameText) {
        defaultsKey = @"Username";
    } else if(textField == self.passwordText) {
        defaultsKey = @"Password";
    } else {
        assert(NO);
        defaultsKey = nil;
    }
    
    newValue = textField.text;
    oldValue = [[NSUserDefaults standardUserDefaults] stringForKey:defaultsKey];
    
    // Save the value if it's changed
    assert(newValue != nil);
    assert(oldValue != nil);
    
    if(![newValue isEqual:oldValue]) {
        [[NSUserDefaults standardUserDefaults] setObject:newValue forKey:defaultsKey];
    }
}
 */


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    #pragma unused(textField)
    
    assert( (textField == self.urlText) || (textField == self.usernameText) || (textField == self.passwordText) );
    [textField resignFirstResponder];
    
    return NO;
}


#pragma mark * View controller boilerplate

@synthesize urlLabel = _urlLabel;
@synthesize loginLabel = _loginLabel;

@synthesize urlText = _urlText;
@synthesize usernameText = _usernameText;
@synthesize passwordText = _passwordText;
@synthesize activityIndicator = _activityIndicator;
@synthesize localButton = _localButton;
@synthesize connectButton = _connectButton;

- (void)viewDidLoad
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    CGRect bounds = [[UIScreen mainScreen] applicationFrame];
    self.view = [[UIView alloc] initWithFrame:bounds];
    self.view.backgroundColor = [UIColor blueColor];
    
    self.title = @"FTPhoto";

    self.urlLabel = [[UILabel alloc] init];

    self.urlLabel.backgroundColor = [UIColor blueColor];
    self.urlLabel.text = @"Connect to FTP Server";
    
    self.urlText = [[UITextField alloc] init];
    self.urlText.delegate = self;
    self.urlText.borderStyle = UITextBorderStyleRoundedRect;
    self.urlText.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.urlText.text = @"ftp://127.0.0.1/Downloads/";
//    self.urlText.text = @"ftp://ftp.itandem.ru";
    self.urlText.keyboardType = UIKeyboardTypeURL;
    self.urlText.returnKeyType = UIReturnKeyDone;
    
    self.loginLabel = [[UILabel alloc] init];
    self.loginLabel.backgroundColor = [UIColor blueColor];
    self.loginLabel.text = @"Login Details";
    
    self.usernameText = [[UITextField alloc] init];
    self.usernameText.delegate = self;
    self.usernameText.borderStyle = UITextBorderStyleRoundedRect;
    self.usernameText.placeholder = @"Username";
    self.usernameText.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.usernameText.text = @"ukv";
    
    self.passwordText = [[UITextField alloc] init];
    self.passwordText.delegate = self;
    self.passwordText.borderStyle = UITextBorderStyleRoundedRect;
    self.passwordText.placeholder = @"Password";
    self.passwordText.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.passwordText.secureTextEntry = YES;
    self.passwordText.text = @"njgktcc";
    
    self.connectButton = [[UIBarButtonItem alloc] initWithTitle:@"Local" style:UIBarButtonItemStylePlain target:self action:@selector(localButton_Clicked:)];
    self.navigationItem.leftBarButtonItem = self.connectButton;
    
    self.connectButton = [[UIBarButtonItem alloc] initWithTitle:@"Connect" style:UIBarButtonItemStylePlain target:self action:@selector(connectButton_Clicked:)];
    self.navigationItem.rightBarButtonItem = self.connectButton;
    
    [self.view addSubview:self.urlLabel];
    [self.view addSubview:self.urlText];
    
    [self.view addSubview:self.loginLabel];
    [self.view addSubview:self.usernameText];
    [self.view addSubview:self.passwordText];
    
    self.activityIndicator.hidden = YES;
    
    // Toolbar
    _buttons = [[NSMutableArray alloc] init];
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithTitle:@"Add" style:UIBarButtonItemStyleBordered
                                                  target:self action:@selector(addButton_Clicked:)];
    UIBarButtonItem *listButton = [[UIBarButtonItem alloc] initWithTitle:@"List" style:UIBarButtonItemStyleBordered 
                                                                  target:self action:@selector(listButton_Clicked:)];
    [_buttons addObject:addButton];
    [_buttons addObject:listButton];
    [addButton release];
    [listButton release];
    
    self.toolbarItems = _buttons;
    self.navigationController.toolbarHidden = NO;
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    /*
    assert(self.urlText != nil);
    assert(self.usernameText != nil);
    assert(self.passwordText != nil);
    assert(self.activityIndicator != nil);
    assert(self.connectButton != nil);
     */
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
//    self.usernameText.text = @"usename"; //[[NSUserDefaults standardUserDefaults] stringForKey:@"Username"];
//    self.passwordText.text = @"password"; //[[NSUserDefaults standardUserDefaults] stringForKey:@"Password"];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    // Release any retained subviews of the main view.
    self.urlText = nil;
    self.usernameText = nil;
    self.passwordText = nil;
    self.activityIndicator = nil;
    self.localButton = nil;
    self.connectButton = nil;
    
}

- (void)viewWillLayoutSubviews {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    // Super
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"5")) [super viewWillLayoutSubviews];
    
    CGRect bounds = self.view.bounds;
    float offsetX = 20;
    float offsetY = 20;
    self.urlLabel.frame = CGRectMake(offsetX, offsetY, bounds.size.width - 2*offsetX, 30);
    offsetY += self.urlLabel.frame.size.height;

    self.urlText.frame = CGRectMake(offsetX, offsetY, bounds.size.width - 2*offsetX, 30);
    offsetY += self.urlText.frame.size.height + 20;

    self.loginLabel.frame = CGRectMake(offsetX, offsetY, bounds.size.width - 2*offsetX, 30);
    offsetY += self.loginLabel.frame.size.height;

    self.usernameText.frame = CGRectMake(offsetX, offsetY, bounds.size.width - 2*offsetX, 30);
    offsetY += self.usernameText.frame.size.height + 5;

    self.passwordText.frame = CGRectMake(offsetX, offsetY, bounds.size.width - 2*offsetX, 30);

    
    //    CGRect frame = self.view.frame;
    //    NSLog(@"view.bounds: %.0f x %.0f", frame.size.width, frame.size.height);
    
    //self.view.frame = [self frameForMainView];
}



- (void)dealloc {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    [_buttons release];
    
    [_urlLabel release];
    [_loginLabel release];
    [_urlText release];
    [_usernameText release];
    [_passwordText release];
    [_activityIndicator release];
    [_localButton release];
    [_connectButton release];
    
    [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES; //(interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Frame Calculations

/*
- (CGRect)frameForMainView {
    CGRect bounds = [[UIScreen mainScreen] bounds];

    NSLog(@"%.0f x %.0f", bounds.size.width, bounds.size.height);
    return bounds;
}
 */

- (void)addButton_Clicked:(id)sender {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)listButton_Clicked:(id)sender {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

@end

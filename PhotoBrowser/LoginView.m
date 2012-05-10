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
//#import "FtpLs.h"


@interface LoginView ()

// Private methods
- (CGRect)frameForMainView;
@end

@implementation LoginView



- (void)viewWillLayoutSubviews {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    // Super
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"5")) [super viewWillLayoutSubviews];

    
//    CGRect frame = self.view.frame;
//    NSLog(@"view.bounds: %.0f x %.0f", frame.size.width, frame.size.height);
    
    //self.view.frame = [self frameForMainView];
}

- (IBAction)connectAction:(id)sender {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    //CGRect bounds = [self frameForMainView];
    
//    NSMutableArray *photos = [[NSMutableArray alloc] init];
//    for (int i=1; i<=14; ++i) {
//     //        Photo *photo = [Photo photoWithFilePath:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat: @"%d", i + 1] ofType:@"jpg"]];
//        Photo *photo = [Photo photoWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"ftp://127.0.0.1/Downloads/%d.jpg", i]]];
//     
//        [photos addObject:photo];
//    }
              
    //Browser *browser = [[Browser alloc] initWithURL:[NSURL URLWithString:@"ftp://127.0.0.1/Downloads/"]];
    //browser.photos = photos;
    //browser.photosPerPage = 1;
    //[self startConnection];
    
    DirectoryList *dirList = [[DirectoryList alloc] initWithURL:[NSURL URLWithString:@"ftp://127.0.0.1/Downloads/"]];
//    dirList.listEntries = ftpLs.listEntries;
    
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

@synthesize urlText = _urlText;
@synthesize usernameText = _usernameText;
@synthesize passwordText = _passwordText;
@synthesize activityIndicator = _activityIndicator;
@synthesize connectButton = _connectButton;

- (void)viewDidLoad
{
    CGRect bounds = [[UIScreen mainScreen] bounds];
    self.view = [[UIView alloc] initWithFrame:bounds];
    self.view.backgroundColor = [UIColor blueColor];
    
    self.title = @"FTPhoto";
    
    self.urlText = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, bounds.size.width, 30)];
    self.urlText.delegate = self;
    self.urlText.borderStyle = UITextBorderStyleRoundedRect;
    self.urlText.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.urlText.text = @"qwe";
    
    self.usernameText = [[UITextField alloc] initWithFrame:CGRectMake(0, 50, bounds.size.width, 30)];
    self.usernameText.delegate = self;
    self.usernameText.borderStyle = UITextBorderStyleRoundedRect;
    self.usernameText.placeholder = @"Username";
    self.usernameText.clearButtonMode = UITextFieldViewModeWhileEditing;
    
    self.passwordText = [[UITextField alloc] initWithFrame:CGRectMake(0, 100, bounds.size.width, 30)];
    self.passwordText.delegate = self;
    self.passwordText.borderStyle = UITextBorderStyleRoundedRect;
    self.passwordText.placeholder = @"Password";
    self.passwordText.clearButtonMode = UITextFieldViewModeWhileEditing;
    
    self.connectButton = [[UIBarButtonItem alloc] initWithTitle:@"Connect" style:UIBarButtonItemStylePlain target:self action:@selector(connectAction:)];
    self.navigationItem.rightBarButtonItem = self.connectButton;
    
    [self.view addSubview:self.urlText];
    [self.view addSubview:self.usernameText];
    [self.view addSubview:self.passwordText];
    
    self.activityIndicator.hidden = YES;
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
    self.connectButton = nil;
    
}

- (void)dealloc {
    [self->_urlText release];
    [self->_usernameText release];
    [self->_passwordText release];
    [self->_activityIndicator release];
    [self->_connectButton release];
    
    [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES; //(interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Frame Calculations

- (CGRect)frameForMainView {
    CGRect bounds = [[UIScreen mainScreen] bounds];

    NSLog(@"%.0f x %.0f", bounds.size.width, bounds.size.height);
    return bounds;
}

@end

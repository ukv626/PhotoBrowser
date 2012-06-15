//
//  LoginView.h
//  PhotoBrowser
//
//  Created by ukv on 5/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ConnectionsList;

@interface LoginView : UIViewController < UITextFieldDelegate, UIAlertViewDelegate> {
    UILabel *_urlLabel;
    UILabel *_loginLabel;
    
    UITextField *_urlText;
    UITextField *_usernameText;
    UITextField *_passwordText;
//    UIActivityIndicatorView *_activityIndicator;
//    UIBarButtonItem *_localButton;
//    UIBarButtonItem *_connectButton;
    
    ConnectionsList *_delegate;
}

@property (nonatomic, retain) IBOutlet UILabel *urlLabel;
@property (nonatomic, retain) IBOutlet UILabel *loginLabel;
@property (nonatomic, retain) IBOutlet UITextField *urlText;
@property (nonatomic, retain) IBOutlet UITextField *usernameText;
@property (nonatomic, retain) IBOutlet UITextField *passwordText;
//@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *activityIndicator;
//@property (nonatomic, retain) IBOutlet UIBarButtonItem *localButton;
//@property (nonatomic, retain) IBOutlet UIBarButtonItem *connectButton;

@property (nonatomic, assign) ConnectionsList *delegate;

//- (IBAction)localButton_Clicked:(id)sender;
- (IBAction)saveButtonClicked:(id)sender;

- (void)setTextFields:(NSString *)urlStr username:(NSString *)username password:(NSString *)password;

@end

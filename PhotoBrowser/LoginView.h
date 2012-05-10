//
//  LoginView.h
//  PhotoBrowser
//
//  Created by ukv on 5/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoginView : UIViewController < UITextFieldDelegate> {
    UITextField *_urlText;
    UITextField *_usernameText;
    UITextField *_passwordText;
    UIActivityIndicatorView *_activityIndicator;
    UIBarButtonItem *_connectButton;
}

@property (nonatomic, retain) IBOutlet UITextField *urlText;
@property (nonatomic, retain) IBOutlet UITextField *usernameText;
@property (nonatomic, retain) IBOutlet UITextField *passwordText;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *connectButton;

- (IBAction)connectAction :(id)sender;

@end

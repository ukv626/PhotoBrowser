//
//  LoginPreferences.h
//  PhotoBrowser
//
//  Created by ukv on 6/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ConnectionsList;

@interface LoginPreferences : UITableViewController <UITextFieldDelegate> {
    enum Sections {
        connectionSection = 0,
        loginSection,
        otherSection,
        SECTIONS_COUNT
    };
    
    UITextField *_alias;
    UITextField *_server;
    UITextField *_port;
    UISegmentedControl *_protocol;
    UISwitch *_connectionType;
    
    UITextField *_username;
    UITextField *_password;
    
    UISwitch *_cacheMode;
    
    //
    NSArray *_connectionTypes;
    
    ConnectionsList *_delegate;
    NSDictionary *_entry;
}

@property (nonatomic, assign) ConnectionsList *delegate;

- (id)init;
-(void)dealloc;

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView;
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section;
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;

- (void)setAttributes:(NSString *)alias;

@end

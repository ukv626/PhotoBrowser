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
        encodingSection,
        otherSection,
        SECTIONS_COUNT
    };
    
    UITextField *_alias;
    UITextField *_server;
    UITextField *_port;
    UISegmentedControl *_protocol;
    UISegmentedControl *_encodingControl;
    UISwitch *_connectionType;
    UITextField *_encoding;
    
    UITextField *_username;
    UITextField *_password;
    
    UISwitch *_cacheMode;
//    UIPickerView *_pickerView;
//    NSMutableArray *_encodings;
    
    //
    NSArray *_connectionTypes;
    NSArray *_encodingTypes;
    NSArray *_encodingFullTypes;
    
    ConnectionsList *_delegate;
    NSDictionary *_entry;
}

@property (nonatomic, assign) ConnectionsList *delegate;

- (id)init;
- (void)dealloc;

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView;
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section;
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;

- (void)setAttributes:(NSString *)alias;

@end

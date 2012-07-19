//
//  PreviewController.m
//  PhotoBrowser
//
//  Created by ukv on 7/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PreviewController.h"
#import "MWPhotoBrowser.h"

@interface PreviewController ()

@end

@implementation PreviewController
@synthesize browser = _browser;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [self setDataSource:self.dataSource];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)didSelectThumbAtIndex:(NSUInteger)index {
    [_browser jumpToPageAtIndex:index];
    [self.navigationController popViewControllerAnimated:YES];
}

@end

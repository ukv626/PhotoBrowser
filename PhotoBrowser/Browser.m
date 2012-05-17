//
//  Browser.m
//  PhotoBrowser
//
//  Created by ukv on 4/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//


#import "Browser.h"
#import "ZoomingScrollView.h"
//#import "Photo.h"
#import "MBProgressHUD.h"
//#import "SDImageCache.h"
#import "FtpLs.h"



#define PADDING                 10
#define PAGE_INDEX_TAG_OFFSET   1000
#define PAGE_INDEX(page)        ([(page) tag] - PAGE_INDEX_TAG_OFFSET)

// private
@interface Browser () {
    
	// Data
    NSArray *_photos;
	
	// Views
	UIScrollView *_pagingScrollView;
	
	// Paging
	NSMutableSet *_visiblePages, *_recycledPages;
	NSUInteger _currentPageIndex;
	NSUInteger _pageIndexBeforeRotation;
	
	// Navigation & controls
	UIToolbar *_toolbar;
	NSTimer *_controlVisibilityTimer;
	UIBarButtonItem *_previousButton, *_nextButton, *_actionButton, *_zoomOutButton;
    UIActionSheet *_actionsSheet;
    MBProgressHUD *_progressHUD;
    
    // Appearance
    UIImage *_navigationBarBackgroundImageDefault, 
    *_navigationBarBackgroundImageLandscapePhone;
    UIColor *_previousNavBarTintColor;
    UIBarStyle _previousNavBarStyle;
    UIStatusBarStyle _previousStatusBarStyle;
    UIBarButtonItem *_previousViewControllerBackButton;
    
    // FtpLs
//    FtpLs *_ftpLs;
    
    // Misc
    NSUInteger _photosPerPage;
    BOOL _displayActionButton;
	BOOL _performingLayout;
	BOOL _rotating;
    BOOL _viewIsActive; // active as in it's in the view heirarchy
    BOOL _didSavePreviousStateOfNavBar;
    
}

// Private Properties
@property (nonatomic, retain) UIColor *previousNavBarTintColor;
@property (nonatomic, retain) UIBarButtonItem *previousViewControllerBackButton;
@property (nonatomic, retain) UIImage *navigationBarBackgroundImageDefault, *navigationBarBackgroundImageLandscapePhone;
@property (nonatomic, retain) UIActionSheet *actionsSheet;
@property (nonatomic, retain) MBProgressHUD *progressHUD;
//@property (nonatomic, retain) FtpLs *ftpLs;

// Private Methods

// Layout
- (void)performLayout;

// Nav Bar Appearance
- (void)setNavBarAppearance:(BOOL)animated;
- (void)storePreviousNavBarAppearance;
- (void)restorePreviousNavBarAppearance:(BOOL)animated;

// Paging
- (void)tilePages;
- (BOOL)isDisplayingPageForIndex:(NSUInteger)index;
- (ZoomingScrollView *)pageDisplayedAtIndex:(NSUInteger)index;
- (ZoomingScrollView *)pageDisplayingPhoto:(id<PhotoDelegate>)photo;
- (ZoomingScrollView *)dequeueRecycledPage;
- (void)configurePage:(ZoomingScrollView *)page forIndex:(NSUInteger)index;
- (void)didStartViewingPageAtIndex:(NSUInteger)index prevIndex:(NSUInteger)prevIndex;

// Frames
- (CGRect)frameForPagingScrollView;
- (CGRect)frameForPageAtIndex:(NSUInteger)index;
- (CGSize)contentSizeForPagingScrollView;
- (CGPoint)contentOffsetForPageAtIndex:(NSUInteger)index;
- (CGRect)frameForToolbarAtOrientation:(UIInterfaceOrientation)orientation;
//- (CGRect)frameForCaptionView:(MWCaptionView *)captionView atIndex:(NSUInteger)index;

// Navigation
- (void)updateNavigation;
- (void)jumpToPageAtIndex:(NSUInteger)index;
- (void)gotoPreviousPage;
- (void)gotoNextPage;
- (void)zoomOut;

// Controls
- (void)cancelControlHiding;
- (void)hideControlsAfterDelay;
- (void)setControlsHidden:(BOOL)hidden animated:(BOOL)animated permanent:(BOOL)permanent;
- (void)toggleControls;
- (BOOL)areControlsHidden;

// Data
- (NSUInteger)numberOfPhotos;
- (NSUInteger)numberOfPages;
- (id<PhotoDelegate>)photoAtIndex:(NSUInteger)index;
- (UIImage *)imageForPhoto:(id<PhotoDelegate>)photo;
- (void)loadAdjacentPhotosIfNecessary:(id<PhotoDelegate>)photo;
- (void)releasePageUnderlyingPhotos:(NSUInteger)index;
- (void)releaseAllUnderlyingPhotos;

// Actions
- (void)savePhoto;
//- (void)copyPhoto;
//- (void)emailPhoto;

@end

// Handle depreciations and supress hide warnings
@interface UIApplication (DepreciationWarningSuppresion)
- (void)setStatusBarHidden:(BOOL)hidden animated:(BOOL)animated;
@end

// MWPhotoBrowser
@implementation Browser

// Properties
@synthesize photos = _photos;
@synthesize photosPerPage = _photosPerPage;

@synthesize previousNavBarTintColor = _previousNavBarTintColor;
@synthesize navigationBarBackgroundImageDefault = _navigationBarBackgroundImageDefault,
navigationBarBackgroundImageLandscapePhone = _navigationBarBackgroundImageLandscapePhone;
@synthesize displayActionButton = _displayActionButton, actionsSheet = _actionsSheet;
@synthesize progressHUD = _progressHUD;
@synthesize previousViewControllerBackButton = _previousViewControllerBackButton;

//@synthesize ftpLs = _ftpLs;

#pragma mark - NSObject

- (id)init {
    if ((self = [super init])) {
        
        // Defaults
        self.wantsFullScreenLayout = YES;
        self.hidesBottomBarWhenPushed = YES;
        
        //_photos = [[NSArray alloc] init];
        _photosPerPage = NSNotFound;

		_currentPageIndex = 0;
		_performingLayout = NO; // Reset on view did appear
		_rotating = NO;
        _viewIsActive = NO;
        _visiblePages = [[NSMutableSet alloc] init];
        _recycledPages = [[NSMutableSet alloc] init];        
        _displayActionButton = YES;
        _didSavePreviousStateOfNavBar = NO;
        
        
//        // Listen for Photo notifications
//        [[NSNotificationCenter defaultCenter] addObserver:self
//                                                 selector:@selector(handlePhotoLoadingDidEndNotification:)
//                                                     name:PHOTO_LOADING_DID_END_NOTIFICATION
//                                                   object:nil];
         
    }
    return self;
}



- (id)initWithPhotos:(NSArray *)photosArray photosPerPage:(NSUInteger)photosPerPage {
	if ((self = [self init])) {
		self.photos = photosArray;
        
        for (Photo *photo in self.photos) {
            photo.delegate = self;
        }
        //NSLog(@"Browser: photos.retainCount=%d", [self.photos retainCount]);
        _photosPerPage = photosPerPage;
	}
	return self;
}


- (void)dealloc {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
//    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_previousNavBarTintColor release];
    [_navigationBarBackgroundImageDefault release];
    [_navigationBarBackgroundImageLandscapePhone release];
    [_previousViewControllerBackButton release];
	[_pagingScrollView release];
	[_visiblePages release];
	[_recycledPages release];
	[_toolbar release];
	[_previousButton release];
	[_nextButton release];
    [_actionButton release];
    [_zoomOutButton release];
    [self releaseAllUnderlyingPhotos];
    
    
//    [[SDImageCache sharedImageCache] clearMemory]; // clear memory
    [_photos release];
    [_progressHUD release];
    [super dealloc];
}

- (void)releasePageUnderlyingPhotos:(NSUInteger)index {
    NSLog(@"%s:%d", __PRETTY_FUNCTION__, index);

    for (NSUInteger i=0; i<_photosPerPage; i++) {
        id<PhotoDelegate> photo = [self photoAtIndex:index*_photosPerPage + i];
        if(photo) {
            [photo unloadUnderlyingImage];
            //[photos replaceObjectAtIndex:i withObject:[NSNull null]];
        }
    }
}

- (void)releaseAllUnderlyingPhotos {
    for (id p in _photos) { 
        if (p != [NSNull null]) {
            [p unloadUnderlyingImage]; 
        }
    } // Release photos
}

- (void)loadPageUnderlyingPhotos:(NSUInteger)index {
    NSLog(@"%s:%d", __PRETTY_FUNCTION__, index);

    for (NSUInteger i=0; i<_photosPerPage; i++) {
        id<PhotoDelegate> photo = [self photoAtIndex:index*_photosPerPage + i];
        if(photo && ![photo underlyingImage]) {            
            [photo loadUnderlyingImageAndNotify];
        }
    }
}


- (void)didReceiveMemoryWarning {
	
	// Release any cached data, Photos, etc that aren't in use.
    [self releaseAllUnderlyingPhotos];
	[_recycledPages removeAllObjects];
	
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
}

#pragma mark - View Loading

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
//    CGRect frame = [[UIScreen mainScreen] bounds];
//    NSLog(@"browser.viewDidLoad: %.0f x %.0f", frame.size.width, frame.size.height);
	
	// View
	self.view.backgroundColor = [UIColor blackColor];
	
	// Setup paging scrolling view
	CGRect pagingScrollViewFrame = [self frameForPagingScrollView];
	_pagingScrollView = [[UIScrollView alloc] initWithFrame:pagingScrollViewFrame];
	_pagingScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	_pagingScrollView.pagingEnabled = YES;
	_pagingScrollView.delegate = self;
	_pagingScrollView.showsHorizontalScrollIndicator = NO;
	_pagingScrollView.showsVerticalScrollIndicator = NO;
	_pagingScrollView.backgroundColor = [UIColor blackColor];
    _pagingScrollView.contentSize = [self contentSizeForPagingScrollView];
	[self.view addSubview:_pagingScrollView];
	
    // Toolbar
    _toolbar = [[UIToolbar alloc] initWithFrame:[self frameForToolbarAtOrientation:self.interfaceOrientation]];
    _toolbar.tintColor = nil;
    if ([[UIToolbar class] respondsToSelector:@selector(appearance)]) {
        [_toolbar setBackgroundImage:nil forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
        [_toolbar setBackgroundImage:nil forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsLandscapePhone];
    }
    _toolbar.barStyle = UIBarStyleBlackTranslucent;
    _toolbar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    
    // Toolbar Items
    _zoomOutButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(zoomOut)];
    
    _previousButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"UIBarButtonItemArrowLeft.png"] style:UIBarButtonItemStylePlain target:self action:@selector(gotoPreviousPage)];
    _nextButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"UIBarButtonItemArrowRight.png"] style:UIBarButtonItemStylePlain target:self action:@selector(gotoNextPage)];
    _actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionButtonPressed:)];
    
    // Update
    [self reloadData];
    
    // Super
    [super viewDidLoad];
}

- (void)performLayout {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    // Setup
    _performingLayout = YES;
    
	// Setup pages
    [_visiblePages removeAllObjects];
    [_recycledPages removeAllObjects];
    
    // Toolbar
    if ([self numberOfPages] > 1 || _displayActionButton) {
        [self.view addSubview:_toolbar];
    } else {
        [_toolbar removeFromSuperview];
    }
    
    // Toolbar items & navigation
    UIBarButtonItem *fixedLeftSpace = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:self action:nil] autorelease];
    fixedLeftSpace.width = 32; // To balance action button
    UIBarButtonItem *flexSpace = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil] autorelease];
    NSMutableArray *items = [[NSMutableArray alloc] init];
    
    [items addObject:_zoomOutButton];
    //[items addObject:flexSpace];
    
    //if (_displayActionButton) [items addObject:fixedLeftSpace];
    [items addObject:flexSpace];
    if ([self numberOfPages] > 1) [items addObject:_previousButton];
    [items addObject:flexSpace];
    if ([self numberOfPages] > 1) [items addObject:_nextButton];
    [items addObject:flexSpace];
    if (_displayActionButton) [items addObject:_actionButton];
    [_toolbar setItems:items];
    [items release];
	[self updateNavigation];
    
    // Navigation buttons
    if ([self.navigationController.viewControllers objectAtIndex:0] == self) {
        // We're first on stack so show done button
        UIBarButtonItem *doneButton = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", nil) style:UIBarButtonItemStylePlain target:self action:@selector(doneButtonPressed:)] autorelease];
        // Set appearance
        if ([UIBarButtonItem respondsToSelector:@selector(appearance)]) {
            [doneButton setBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
            [doneButton setBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsLandscapePhone];
            [doneButton setBackgroundImage:nil forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
            [doneButton setBackgroundImage:nil forState:UIControlStateHighlighted barMetrics:UIBarMetricsLandscapePhone];
            [doneButton setTitleTextAttributes:[NSDictionary dictionary] forState:UIControlStateNormal];
            [doneButton setTitleTextAttributes:[NSDictionary dictionary] forState:UIControlStateHighlighted];
        }
        self.navigationItem.rightBarButtonItem = doneButton;
    } else {
        // We're not first so show back button
        UIViewController *previousViewController = [self.navigationController.viewControllers objectAtIndex:self.navigationController.viewControllers.count-2];
        NSString *backButtonTitle = previousViewController.navigationItem.backBarButtonItem ? previousViewController.navigationItem.backBarButtonItem.title : previousViewController.title;
        UIBarButtonItem *newBackButton = [[[UIBarButtonItem alloc] initWithTitle:backButtonTitle style:UIBarButtonItemStylePlain target:nil action:nil] autorelease];
        // Appearance
        if ([UIBarButtonItem respondsToSelector:@selector(appearance)]) {
            [newBackButton setBackButtonBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
            [newBackButton setBackButtonBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsLandscapePhone];
            [newBackButton setBackButtonBackgroundImage:nil forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
            [newBackButton setBackButtonBackgroundImage:nil forState:UIControlStateHighlighted barMetrics:UIBarMetricsLandscapePhone];
            [newBackButton setTitleTextAttributes:[NSDictionary dictionary] forState:UIControlStateNormal];
            [newBackButton setTitleTextAttributes:[NSDictionary dictionary] forState:UIControlStateHighlighted];
        }
        self.previousViewControllerBackButton = previousViewController.navigationItem.backBarButtonItem; // remember previous
        previousViewController.navigationItem.backBarButtonItem = newBackButton;
    }
    
    // Content offset
	_pagingScrollView.contentOffset = [self contentOffsetForPageAtIndex:_currentPageIndex];
    [self tilePages];
    _performingLayout = NO;    
}

// Release any retained subviews of the main view.
- (void)viewDidUnload {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
	_currentPageIndex = 0;
    [_pagingScrollView release], _pagingScrollView = nil;
    [_visiblePages release], _visiblePages = nil;
    [_recycledPages release], _recycledPages = nil;
    [_toolbar release], _toolbar = nil;
    [_previousButton release], _previousButton = nil;
    [_nextButton release], _nextButton = nil;
    self.progressHUD = nil;
    [super viewDidUnload];
}

#pragma mark - Appearance

- (void)viewWillAppear:(BOOL)animated {
    
	// Super
	[super viewWillAppear:animated];
	
	// Layout manually (iOS < 5)
    if (SYSTEM_VERSION_LESS_THAN(@"5")) [self viewWillLayoutSubviews];
    
    // Status bar
    if (self.wantsFullScreenLayout && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        _previousStatusBarStyle = [[UIApplication sharedApplication] statusBarStyle];
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:animated];
    }
    
    // Navigation bar appearance
    if (!_viewIsActive && [self.navigationController.viewControllers objectAtIndex:0] != self) {
        [self storePreviousNavBarAppearance];
    }
    [self setNavBarAppearance:animated];
    
    // Update UI
	[self hideControlsAfterDelay];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    // Check that we're being popped for good
    if ([self.navigationController.viewControllers objectAtIndex:0] != self &&
        ![self.navigationController.viewControllers containsObject:self]) {
        
        // State
        _viewIsActive = NO;
        
        // Bar state / appearance
        [self restorePreviousNavBarAppearance:animated];
        
    }
    
    // Controls
//    [self.navigationController.navigationBar.layer removeAllAnimations]; // Stop all animations on nav bar
    [NSObject cancelPreviousPerformRequestsWithTarget:self]; // Cancel any pending toggles from taps
    [self setControlsHidden:NO animated:NO permanent:YES];
    
    // Status bar
    if (self.wantsFullScreenLayout && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [[UIApplication sharedApplication] setStatusBarStyle:_previousStatusBarStyle animated:animated];
    }
    
	// Super
	[super viewWillDisappear:animated];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    _viewIsActive = YES;
}

#pragma mark - Nav Bar Appearance

- (void)setNavBarAppearance:(BOOL)animated {
    self.navigationController.navigationBar.tintColor = nil;
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
    if ([[UINavigationBar class] respondsToSelector:@selector(appearance)]) {
        [self.navigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
        [self.navigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsLandscapePhone];
    }
}

- (void)storePreviousNavBarAppearance {
    _didSavePreviousStateOfNavBar = YES;
    self.previousNavBarTintColor = self.navigationController.navigationBar.tintColor;
    _previousNavBarStyle = self.navigationController.navigationBar.barStyle;
    if ([[UINavigationBar class] respondsToSelector:@selector(appearance)]) {
        self.navigationBarBackgroundImageDefault = [self.navigationController.navigationBar backgroundImageForBarMetrics:UIBarMetricsDefault];
        self.navigationBarBackgroundImageLandscapePhone = [self.navigationController.navigationBar backgroundImageForBarMetrics:UIBarMetricsLandscapePhone];
    }
}

- (void)restorePreviousNavBarAppearance:(BOOL)animated {
    if (_didSavePreviousStateOfNavBar) {
        self.navigationController.navigationBar.tintColor = _previousNavBarTintColor;
        self.navigationController.navigationBar.barStyle = _previousNavBarStyle;
        if ([[UINavigationBar class] respondsToSelector:@selector(appearance)]) {
            [self.navigationController.navigationBar setBackgroundImage:_navigationBarBackgroundImageDefault forBarMetrics:UIBarMetricsDefault];
            [self.navigationController.navigationBar setBackgroundImage:_navigationBarBackgroundImageLandscapePhone forBarMetrics:UIBarMetricsLandscapePhone];
        }
        // Restore back button if we need to
        if (_previousViewControllerBackButton) {
            UIViewController *previousViewController = [self.navigationController topViewController]; // We've disappeared so previous is now top
            previousViewController.navigationItem.backBarButtonItem = _previousViewControllerBackButton;
            self.previousViewControllerBackButton = nil;
        }
    }
}

#pragma mark - Layout

- (void)viewWillLayoutSubviews {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    // Super
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"5")) [super viewWillLayoutSubviews];
	
	// Flag
	_performingLayout = YES;
	
	// Toolbar
	_toolbar.frame = [self frameForToolbarAtOrientation:self.interfaceOrientation];
	
	// Remember index
	NSUInteger indexPriorToLayout = _currentPageIndex;
	
	// Get paging scroll view frame to determine if anything needs changing
	CGRect pagingScrollViewFrame = [self frameForPagingScrollView];
    
	// Frame needs changing
	_pagingScrollView.frame = pagingScrollViewFrame;
	
	// Recalculate contentSize based on current orientation
	_pagingScrollView.contentSize = [self contentSizeForPagingScrollView];
	
	// Adjust frames and configuration of each visible page
	for (ZoomingScrollView *page in _visiblePages) {
        NSUInteger index = PAGE_INDEX(page);
        page.frame = [self frameForPageAtIndex:index];
        page.captionView.frame = [self frameForCaptionView:page.captionView atIndex:index];

        [page setMaxMinZoomScalesForCurrentBounds];
	}
	
	// Adjust contentOffset to preserve page location based on values collected prior to location
	_pagingScrollView.contentOffset = [self contentOffsetForPageAtIndex:indexPriorToLayout];
	
    // initial
    [self didStartViewingPageAtIndex:_currentPageIndex prevIndex:_currentPageIndex]; 
    
	// Reset
	_currentPageIndex = indexPriorToLayout;
	_performingLayout = NO;
     
}

#pragma mark - Rotation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	// Remember page index before rotation
	_pageIndexBeforeRotation = _currentPageIndex;
	_rotating = YES;
	
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	// Perform layout
	_currentPageIndex = _pageIndexBeforeRotation;
    
	// Layout manually (iOS < 5)
    if (SYSTEM_VERSION_LESS_THAN(@"5")) [self viewWillLayoutSubviews];
	
	// Delay control holding
	[self hideControlsAfterDelay];	
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	_rotating = NO;
    
    // Adjust frames and configuration of each visible page
    for (ZoomingScrollView *page in _visiblePages) {
        NSUInteger index = PAGE_INDEX(page);
        page.frame = [self frameForPageAtIndex:index];
        //        page.captionView.frame = [self frameForCaptionView:page.captionView atIndex:index];
        
        [page setMaxMinZoomScalesForCurrentBounds];
	}
}

- (void)reload:(NSUInteger)photosPerPage imageIndex:(NSUInteger)imageIndex{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    // Perform layout

    // release adjucent pages
    if(_currentPageIndex > 0)
        [self releasePageUnderlyingPhotos:_currentPageIndex - 1];
    if(_currentPageIndex < [self numberOfPhotos] - 1)
        [self releasePageUnderlyingPhotos:_currentPageIndex + 1];
    
    // calculate new current page
    if(_photosPerPage > photosPerPage)
        _currentPageIndex = _photosPerPage * _currentPageIndex + imageIndex;
    else 
        _currentPageIndex = _currentPageIndex / photosPerPage;

    _photosPerPage = photosPerPage;
    [self performLayout];
    
	// Layout manually (iOS < 5)
//    if (SYSTEM_VERSION_LESS_THAN(@"5")) [self viewWillLayoutSubviews];
	
	// Delay control holding
	[self hideControlsAfterDelay];
}

#pragma mark - Data

- (void)reloadData {
    
    // Reset
    
    // Get data
    //NSUInteger numberOfPhotos = [self numberOfPhotos];
    [self releaseAllUnderlyingPhotos];
    //[photos removeAllObjects];
    //for (int i = 0; i < numberOfPhotos; i++) [_photos addObject:[NSNull null]];
    
    // Update
    [self performLayout];
    
    // Layout
    if (SYSTEM_VERSION_LESS_THAN(@"5")) [self viewWillLayoutSubviews];
    else [self.view setNeedsLayout];
    
}


- (NSUInteger)numberOfPages {
    NSUInteger pagesCount, photosCount = [self numberOfPhotos];
        
    if(photosCount % _photosPerPage)
        pagesCount = photosCount / _photosPerPage + 1;
    else 
        pagesCount = photosCount / _photosPerPage;
    
//    NSLog(@"%s %d %d %d",__PRETTY_FUNCTION__, _photosCount, _photosOnPageCount, _pagesCount);
    return pagesCount;
}



- (NSUInteger)numberOfPhotos {
    return [_photos count];
}



- (id<PhotoDelegate>)photoAtIndex:(NSUInteger)index {
    id<PhotoDelegate> photo = nil;
    if (index < _photos.count) {
       photo = [_photos objectAtIndex:index];
    }
    return photo;
}

- (CaptionView *)captionViewForPhotoAtIndex:(NSUInteger)index {
    CaptionView *captionView = nil;
    id <PhotoDelegate> photo = [self photoAtIndex:index];
    if ([photo respondsToSelector:@selector(caption)]) {
        if ([photo caption]) captionView = [[[CaptionView alloc] initWithPhoto:photo] autorelease];
    }
    captionView.alpha = [self areControlsHidden] ? 0 : 1; // Initial alpha
    return captionView;
}

- (UIImage *)imageForPhoto:(id<PhotoDelegate>)photo {
//    NSLog(@"imageForPhoto");
    if(photo) {
        // Get image or obtain in background
        if([photo underlyingImage]) {
            return [photo underlyingImage];
        } else {
            [photo loadUnderlyingImageAndNotify];
        }
    }
	return nil;
}

- (void)loadAdjacentPhotosIfNecessary:(id<PhotoDelegate>)photo {
    NSLog(@"loadAdjacentPhotosIfNecessary");
    /*
    ZoomingScrollView *page = [self pageDisplayingPhoto:photo];
    if (page) {
        // If page is current page then initiate loading of previous and next pages
        NSUInteger pageIndex = PAGE_INDEX(page);
        if (_currentPageIndex == pageIndex) {
            if (pageIndex > 0) {
                // Preload index - 1
                id<PhotoDelegate> photo = [self photoAtIndex:pageIndex-1];
                if (![photo underlyingImage]) {
                    [photo loadUnderlyingImageAndNotify];
                    NSLog(@"Pre-loading image at index %i", pageIndex-1);
                }
            }
            if (pageIndex < [self numberOfPhotos] - 1) {
                // Preload index + 1
                id<PhotoDelegate> photo = [self photoAtIndex:pageIndex+1];
                if (![photo underlyingImage]) {
                    [photo loadUnderlyingImageAndNotify];
                    NSLog(@"Pre-loading image at index %i", pageIndex+1);
                }
            }
        }
    }
     */
}

#pragma mark - Loading Notifications

- (void)handleLoadingDidEndNotification:(id)sender {
    if([sender class] == [Photo class]) {
        Photo *photo = sender;
        NSLog(@"get notification about: %d %@", photo.photoNumber, photo.photoPath );
        ZoomingScrollView *page = [self pageDisplayingPhoto:photo];
        if (page) {
            if ([photo underlyingImage]) {
                // Successful load
                [page displayImageAtIndex:photo.photoNumber];
                //[self loadAdjacentPhotosIfNecessary:photo];
            } else {
                // Failed to load
                [page displayImageFailure];
            }
        }
    }
}



#pragma mark - Paging

- (void)tilePages {
	// Calculate which pages should be visible
	// Ignore padding as paging bounces encroach on that
	// and lead to false page loads
	CGRect visibleBounds = _pagingScrollView.bounds;
	int iFirstIndex = (int)floorf((CGRectGetMinX(visibleBounds)+PADDING*2) / CGRectGetWidth(visibleBounds));
	int iLastIndex  = (int)floorf((CGRectGetMaxX(visibleBounds)-PADDING*2-1) / CGRectGetWidth(visibleBounds));
    if (iFirstIndex < 0) iFirstIndex = 0;
    if (iFirstIndex > [self numberOfPages] - 1) iFirstIndex = [self numberOfPages] - 1;
    if (iLastIndex < 0) iLastIndex = 0;
    if (iLastIndex > [self numberOfPages] - 1) iLastIndex = [self numberOfPages] - 1;
	
	// Recycle no longer needed pages
    NSInteger pageIndex;
	for (ZoomingScrollView *page in _visiblePages) {
        pageIndex = PAGE_INDEX(page);
		if (pageIndex < (NSUInteger)iFirstIndex || pageIndex > (NSUInteger)iLastIndex) {
			[_recycledPages addObject:page];
            [page prepareForReuse];
			[page removeFromSuperview];
			NSLog(@"Removed page at index %i", PAGE_INDEX(page));
		}
	}
	[_visiblePages minusSet:_recycledPages];
    while (_recycledPages.count > 2) // Only keep 2 recycled pages
        [_recycledPages removeObject:[_recycledPages anyObject]];
	
	// Add missing pages
	for (NSUInteger index = (NSUInteger)iFirstIndex; index <= (NSUInteger)iLastIndex; index++) {
		if (![self isDisplayingPageForIndex:index]) {
            
            // Add new page
            NSLog(@"Added page at index %i", index);
			ZoomingScrollView *page = [self dequeueRecycledPage];
			if (!page) {
				page = [[[ZoomingScrollView alloc] initWithBrowser:self] autorelease];
			}
			[self configurePage:page forIndex:index];
			[_visiblePages addObject:page];
			[_pagingScrollView addSubview:page];
			
            
            // Add caption
            if(self.photosPerPage == 1) {
                CaptionView *captionView = [self captionViewForPhotoAtIndex:index];
                captionView.frame = [self frameForCaptionView:captionView atIndex:index];
                [_pagingScrollView addSubview:captionView];
                page.captionView = captionView;
            }
            
		}
	}
	
}

- (BOOL)isDisplayingPageForIndex:(NSUInteger)index {
	for (ZoomingScrollView *page in _visiblePages)
		if (PAGE_INDEX(page) == index) return YES;
	return NO;
}

- (ZoomingScrollView *)pageDisplayedAtIndex:(NSUInteger)index {
	ZoomingScrollView *thePage = nil;
	for (ZoomingScrollView *page in _visiblePages) {
		if (PAGE_INDEX(page) == index) {
			thePage = page; 
            break;
		}
	}
	return thePage;
}

- (ZoomingScrollView *)pageDisplayingPhoto:(id<PhotoDelegate>)photo {
	ZoomingScrollView *thePage = nil;
	for (ZoomingScrollView *page in _visiblePages) {
        for (NSUInteger i=0; i<[page.photos count]; i++) {
            if([page.photos objectAtIndex:i] == photo) {
                thePage = page; 
                break;
            }
		}
	}
	return thePage;
}

- (void)configurePage:(ZoomingScrollView *)page forIndex:(NSUInteger)index {
    NSLog(@"configurePage: %d", index);
	page.frame = [self frameForPageAtIndex:index];
    page.tag = PAGE_INDEX_TAG_OFFSET + index;
    
    NSMutableArray *pagePhotos = [[NSMutableArray alloc] init];
    for (NSUInteger i=0; i<_photosPerPage; i++) {
        id<PhotoDelegate> photo = [self photoAtIndex:index*_photosPerPage + i];
        if(photo) {
            [pagePhotos addObject:photo];
            [photo release];
        }
    }
    page.photos = pagePhotos;
}

- (ZoomingScrollView *)dequeueRecycledPage {
	ZoomingScrollView *page = [_recycledPages anyObject];
	if (page) {
		[[page retain] autorelease];
		[_recycledPages removeObject:page];
	}
	return page;
}

// Handle page changes
- (void)didStartViewingPageAtIndex:(NSUInteger)index prevIndex:(NSUInteger)prevIndex {
    NSLog(@"%s:%d %d", __PRETTY_FUNCTION__, index, prevIndex);
    
    if(index > prevIndex) { // -->
        if(index >= 2)
            [self releasePageUnderlyingPhotos:index - 2];
        if(index <= [self numberOfPages] - 1)
            [self loadPageUnderlyingPhotos:index + 1];
    } else if(index < prevIndex) { // <--
        if(index <= [self numberOfPages] - 2)
            [self releasePageUnderlyingPhotos:index + 2];
    
        if(index >= 1)
            [self loadPageUnderlyingPhotos:index - 1]; 
    } else {
        // load adjucent pages
        if(_currentPageIndex > 0)
            [self loadPageUnderlyingPhotos:_currentPageIndex - 1];
        if(_currentPageIndex < [self numberOfPhotos] - 1)
            [self loadPageUnderlyingPhotos:_currentPageIndex + 1];
    }
        
	// Recycle no longer needed pages
//    NSInteger pageIndex;
//	for (ZoomingScrollView *page in _visiblePages) {
//        pageIndex = PAGE_INDEX(page);
//		if (pageIndex < (NSUInteger)iFirstIndex || pageIndex > (NSUInteger)iLastIndex) {
//			[_recycledPages addObject:page];
//            [page prepareForReuse];
//			[page removeFromSuperview];
//			NSLog(@"Removed page at index %i", PAGE_INDEX(page));
//		}
//	}

    // Release Photos further away than +/-1
//    if(index - 2 >= 0)
//        [self releasePageUnderlyingPhotos:index - 2]; 
//    
//    if(index < [self numberOfPages] - 1)
//    NSUInteger i;
//    if (index > 0) {
//        // Release anything < index - 1
//        for (i = 0; i < index-1; i++) { 
//            id photo = [_photos objectAtIndex:i];
//            if (photo != [NSNull null]) {
//                [photo unloadUnderlyingImage];
//                [_photos replaceObjectAtIndex:i withObject:[NSNull null]];
////                NSLog(@"Released underlying image at index %i", i);
//            }
//        }
//    }
//    if (index < [self numberOfPages] - 1) {
//        // Release anything > index + 1
//        for (i = index + 2; i < _photos.count; i++) {
//            id photo = [_photos objectAtIndex:i];
//            if (photo != [NSNull null]) {
//                [photo unloadUnderlyingImage];
//                [_photos replaceObjectAtIndex:i withObject:[NSNull null]];
////                NSLog(@"Released underlying image at index %i", i);
//            }
//        }
//    }
    

//    // Load adjacent Photos if needed and the photo is already
//    // loaded. Also called after photo has been loaded in background
//    id<PhotoDelegate> currentPhoto = [self photoAtIndex:index];
//    if ([currentPhoto underlyingImage]) {
//        // photo loaded so load ajacent now
//        [self loadAdjacentPhotosIfNecessary:currentPhoto];
//    }
    
}

#pragma mark - Frame Calculations

- (CGRect)frameForPagingScrollView {
    CGRect frame = self.view.bounds; //[[UIScreen mainScreen] bounds];
    NSLog(@"browser: %.0f x %.0f", frame.size.width, frame.size.height);
    frame.origin.x -= PADDING;
    frame.size.width += (2 * PADDING);
    return frame;
}

- (CGRect)frameForPageAtIndex:(NSUInteger)index {
    // We have to use our paging scroll view's bounds, not frame, to calculate the page placement. When the device is in
    // landscape orientation, the frame will still be in portrait because the pagingScrollView is the root view controller's
    // view, so its frame is in window coordinate space, which is never rotated. Its bounds, however, will be in landscape
    // because it has a rotation transform applied.
    CGRect bounds = _pagingScrollView.bounds;
    CGRect pageFrame = bounds;
    pageFrame.size.width -= (2 * PADDING);
    pageFrame.origin.x = (bounds.size.width * index) + PADDING;
    return pageFrame;
}

- (CGSize)contentSizeForPagingScrollView {
    // We have to use the paging scroll view's bounds to calculate the contentSize, for the same reason outlined above.
    CGRect bounds = _pagingScrollView.bounds;
    return CGSizeMake(bounds.size.width * [self numberOfPages], bounds.size.height);
}

- (CGPoint)contentOffsetForPageAtIndex:(NSUInteger)index {
	CGFloat pageWidth = _pagingScrollView.bounds.size.width;
	CGFloat newOffset = index * pageWidth;
	return CGPointMake(newOffset, 0);
}

- (CGRect)frameForToolbarAtOrientation:(UIInterfaceOrientation)orientation {
    CGFloat height = 44;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone &&
        UIInterfaceOrientationIsLandscape(orientation)) height = 32;
	return CGRectMake(0, self.view.bounds.size.height - height, self.view.bounds.size.width, height);
}

- (CGRect)frameForCaptionView:(CaptionView *)captionView atIndex:(NSUInteger)index {
    CGRect pageFrame = [self frameForPageAtIndex:index];
    captionView.frame = CGRectMake(0, 0, pageFrame.size.width, 44); // set initial frame
    CGSize captionSize = [captionView sizeThatFits:CGSizeMake(pageFrame.size.width, 0)];
    CGRect captionFrame = CGRectMake(pageFrame.origin.x, pageFrame.size.height - captionSize.height - (_toolbar.superview?_toolbar.frame.size.height:0), pageFrame.size.width, captionSize.height);
    return captionFrame;
}

#pragma mark - UIScrollView Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	
    // Checks
	if (!_viewIsActive || _performingLayout || _rotating) return;
	
	// Tile pages
	[self tilePages];
	
	// Calculate current page
	CGRect visibleBounds = _pagingScrollView.bounds;
	int index = (int)(floorf(CGRectGetMidX(visibleBounds) / CGRectGetWidth(visibleBounds)));
    if (index < 0) index = 0;
	if (index > [self numberOfPages] - 1) index = [self numberOfPages] - 1;
	NSUInteger previousCurrentPage = _currentPageIndex;
	_currentPageIndex = index;
	if (_currentPageIndex != previousCurrentPage) {
        [self didStartViewingPageAtIndex:index prevIndex:previousCurrentPage];
    }
	
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	// Hide controls when dragging begins
	[self setControlsHidden:YES animated:YES permanent:NO];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	// Update nav when page changes
	[self updateNavigation];
}

#pragma mark - Navigation

- (void)updateNavigation {
    
	// Title
	if ([self numberOfPages] > 1) {
		self.title = [NSString stringWithFormat:@"%i %@ %i", _currentPageIndex+1, NSLocalizedString(@"of", @"Used in the context: 'Showing 1 of 3 items'"), [self numberOfPages]];		
	} else {
		self.title = nil;
	}
	
	// Buttons
	_previousButton.enabled = (_currentPageIndex > 0);
	_nextButton.enabled = (_currentPageIndex < [self numberOfPages] - 1);
    _zoomOutButton.enabled = _photosPerPage == 1;
	_actionButton.enabled = _photosPerPage == 1;
}

- (void)jumpToPageAtIndex:(NSUInteger)index {
	
	// Change page
	if (index < [self numberOfPhotos]) {
		CGRect pageFrame = [self frameForPageAtIndex:index];
		_pagingScrollView.contentOffset = CGPointMake(pageFrame.origin.x - PADDING, 0);
		[self updateNavigation];
	}
	
	// Update timer to give more time
	[self hideControlsAfterDelay];
	
}

- (void)gotoPreviousPage { [self jumpToPageAtIndex:_currentPageIndex-1]; }
- (void)gotoNextPage { [self jumpToPageAtIndex:_currentPageIndex+1]; }

- (void)zoomOut {
    [self reload:4 imageIndex:0];
}

#pragma mark - Control Hiding / Showing

// If permanent then we don't set timers to hide again
- (void)setControlsHidden:(BOOL)hidden animated:(BOOL)animated permanent:(BOOL)permanent {
    
    // Cancel any timers
    [self cancelControlHiding];
	
	// Status bar and nav bar positioning
    if (self.wantsFullScreenLayout) {
        
        // Get status bar height if visible
        CGFloat statusBarHeight = 0;
        if (![UIApplication sharedApplication].statusBarHidden) {
            CGRect statusBarFrame = [[UIApplication sharedApplication] statusBarFrame];
            statusBarHeight = MIN(statusBarFrame.size.height, statusBarFrame.size.width);
        }
        
        // Status Bar
        if ([UIApplication instancesRespondToSelector:@selector(setStatusBarHidden:withAnimation:)]) {
            [[UIApplication sharedApplication] setStatusBarHidden:hidden withAnimation:animated?UIStatusBarAnimationFade:UIStatusBarAnimationNone];
        } else {
            [[UIApplication sharedApplication] setStatusBarHidden:hidden animated:animated];
        }
        
        // Get status bar height if visible
        if (![UIApplication sharedApplication].statusBarHidden) {
            CGRect statusBarFrame = [[UIApplication sharedApplication] statusBarFrame];
            statusBarHeight = MIN(statusBarFrame.size.height, statusBarFrame.size.width);
        }
        
        // Set navigation bar frame
        CGRect navBarFrame = self.navigationController.navigationBar.frame;
        navBarFrame.origin.y = statusBarHeight;
        self.navigationController.navigationBar.frame = navBarFrame;
        
    }
    
    // Captions
    NSMutableSet *captionViews = [[[NSMutableSet alloc] initWithCapacity:_visiblePages.count] autorelease];
    for (ZoomingScrollView *page in _visiblePages) {
        if (page.captionView) [captionViews addObject:page.captionView];
    }
	
	// Animate
    if (animated) {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.35];
    }
    CGFloat alpha = hidden ? 0 : 1;
	[self.navigationController.navigationBar setAlpha:alpha];
	[_toolbar setAlpha:alpha];
    for (UIView *v in captionViews) v.alpha = alpha;
	if (animated) [UIView commitAnimations];
	
	// Control hiding timer
	// Will cancel existing timer but only begin hiding if
	// they are visible
	if (!permanent) [self hideControlsAfterDelay];
	
}

- (void)cancelControlHiding {
	// If a timer exists then cancel and release
	if (_controlVisibilityTimer) {
		[_controlVisibilityTimer invalidate];
		[_controlVisibilityTimer release];
		_controlVisibilityTimer = nil;
	}
}

// Enable/disable control visiblity timer
- (void)hideControlsAfterDelay {
	if (![self areControlsHidden]) {
        [self cancelControlHiding];
		_controlVisibilityTimer = [[NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(hideControls) userInfo:nil repeats:NO] retain];
	}
}

- (BOOL)areControlsHidden { return (_toolbar.alpha == 0); /* [UIApplication sharedApplication].isStatusBarHidden; */ }
- (void)hideControls { [self setControlsHidden:YES animated:YES permanent:NO]; }
- (void)toggleControls { [self setControlsHidden:![self areControlsHidden] animated:YES permanent:NO]; }

#pragma mark - Properties

- (void)setInitialPageIndex:(NSUInteger)index {
    // Validate
    if (index >= [self numberOfPhotos]) index = [self numberOfPhotos]-1;
    _currentPageIndex = index;
	if ([self isViewLoaded]) {
        [self jumpToPageAtIndex:index];
        if (!_viewIsActive) [self tilePages]; // Force tiling if view is not visible
    }
}

#pragma mark - Misc

- (void)doneButtonPressed:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)actionButtonPressed:(id)sender {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    if (_actionsSheet) {
        // Dismiss
        [_actionsSheet dismissWithClickedButtonIndex:_actionsSheet.cancelButtonIndex animated:YES];
    } else {
        id <PhotoDelegate> photo = [self photoAtIndex:_currentPageIndex];
        if ([self numberOfPhotos] > 0 && [photo underlyingImage]) {
            
            // Keep controls hidden
            [self setControlsHidden:NO animated:YES permanent:YES];
            
            // Sheet
            self.actionsSheet = [[[UIActionSheet alloc] initWithTitle:nil delegate:self
                                  cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil
                                  otherButtonTitles:NSLocalizedString(@"Save", nil), /*NSLocalizedString(@"Copy", nil),*/ nil] autorelease];

            _actionsSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                [_actionsSheet showFromBarButtonItem:sender animated:YES];
            } else {
                NSLog(@"showInView");
                [_actionsSheet showInView:self.view];
            }
            
        }
    }
    
}


#pragma mark - Action Sheet Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (actionSheet == _actionsSheet) {           
        // Actions 
        self.actionsSheet = nil;
        if (buttonIndex != actionSheet.cancelButtonIndex) {
            if (buttonIndex == actionSheet.firstOtherButtonIndex) {
                [self savePhoto]; return;
            } else if (buttonIndex == actionSheet.firstOtherButtonIndex + 1) {
                [self savePhoto]; return;	
            }
        }
    }
    [self hideControlsAfterDelay]; // Continue as normal...
}

#pragma mark - MBProgressHUD

- (MBProgressHUD *)progressHUD {
    if (!_progressHUD) {
        _progressHUD = [[MBProgressHUD alloc] initWithView:self.view];
        _progressHUD.minSize = CGSizeMake(120, 120);
        _progressHUD.minShowTime = 1;
        // The sample image is based on the
        // work by: http://www.pixelpressicons.com
        // licence: http://creativecommons.org/licenses/by/2.5/ca/
        self.progressHUD.customView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Checkmark.png"]] autorelease];
        [self.view addSubview:_progressHUD];
    }
    return _progressHUD;
}

- (void)showProgressHUDWithMessage:(NSString *)message {
    self.progressHUD.labelText = message;
    self.progressHUD.mode = MBProgressHUDModeIndeterminate;
    [self.progressHUD show:YES];
    self.navigationController.navigationBar.userInteractionEnabled = NO;
}

- (void)hideProgressHUD:(BOOL)animated {
    [self.progressHUD hide:animated];
    self.navigationController.navigationBar.userInteractionEnabled = YES;
}

- (void)showProgressHUDCompleteMessage:(NSString *)message {
    if (message) {
        if (self.progressHUD.isHidden) [self.progressHUD show:YES];
        self.progressHUD.labelText = message;
        self.progressHUD.mode = MBProgressHUDModeCustomView;
        [self.progressHUD hide:YES afterDelay:1.5];
    } else {
        [self.progressHUD hide:YES];
    }
    self.navigationController.navigationBar.userInteractionEnabled = YES;
}

#pragma mark - Actions

- (void)savePhoto {
    id <PhotoDelegate> photo = [self photoAtIndex:_currentPageIndex];
    if ([photo underlyingImage]) {
        [self showProgressHUDWithMessage:[NSString stringWithFormat:@"%@\u2026" , NSLocalizedString(@"Saving", @"Displayed with ellipsis as 'Saving...' when an item is in the process of being saved")]];
        [self performSelector:@selector(actuallySavePhoto:) withObject:photo afterDelay:0];
    }
}

- (void)actuallySavePhoto:(id<PhotoDelegate>)photo {
    if ([photo underlyingImage]) {
        UIImageWriteToSavedPhotosAlbum([photo underlyingImage], self, 
                                       @selector(image:didFinishSavingWithError:contextInfo:), nil);
    }
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    [self showProgressHUDCompleteMessage: error ? NSLocalizedString(@"Failed", @"Informing the user a process has failed") : NSLocalizedString(@"Saved", @"Informing the user an item has been saved")];
    [self hideControlsAfterDelay]; // Continue as normal...
}

//- (void)copyPhoto {
//    id <MWPhoto> photo = [self photoAtIndex:_currentPageIndex];
//    if ([photo underlyingImage]) {
//        [self showProgressHUDWithMessage:[NSString stringWithFormat:@"%@\u2026" , NSLocalizedString(@"Copying", @"Displayed with ellipsis as 'Copying...' when an item is in the process of being copied")]];
//        [self performSelector:@selector(actuallyCopyPhoto:) withObject:photo afterDelay:0];
//    }
//}
//
//- (void)actuallyCopyPhoto:(id<MWPhoto>)photo {
//    if ([photo underlyingImage]) {
//        [[UIPasteboard generalPasteboard] setData:UIImagePNGRepresentation([photo underlyingImage])
//                                forPasteboardType:@"public.png"];
//        [self showProgressHUDCompleteMessage:NSLocalizedString(@"Copied", @"Informing the user an item has finished copying")];
//        [self hideControlsAfterDelay]; // Continue as normal...
//    }
//}
//
//- (void)emailPhoto {
//    id <MWPhoto> photo = [self photoAtIndex:_currentPageIndex];
//    if ([photo underlyingImage]) {
//        [self showProgressHUDWithMessage:[NSString stringWithFormat:@"%@\u2026" , NSLocalizedString(@"Preparing", @"Displayed with ellipsis as 'Preparing...' when an item is in the process of being prepared")]];
//        [self performSelector:@selector(actuallyEmailPhoto:) withObject:photo afterDelay:0];
//    }
//}
//
//- (void)actuallyEmailPhoto:(id<MWPhoto>)photo {
//    if ([photo underlyingImage]) {
//        MFMailComposeViewController *emailer = [[MFMailComposeViewController alloc] init];
//        emailer.mailComposeDelegate = self;
//        [emailer setSubject:NSLocalizedString(@"Photo", nil)];
//        [emailer addAttachmentData:UIImagePNGRepresentation([photo underlyingImage]) mimeType:@"png" fileName:@"Photo.png"];
//        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
//            emailer.modalPresentationStyle = UIModalPresentationPageSheet;
//        }
//        [self presentModalViewController:emailer animated:YES];
//        [emailer release];
//        [self hideProgressHUD:NO];
//    }
//}
//
//#pragma mark Mail Compose Delegate
//
//- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
//    if (result == MFMailComposeResultFailed) {
//		UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Email", nil)
//                                                         message:NSLocalizedString(@"Email failed to send. Please try again.", nil)
//                                                        delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil] autorelease];
//		[alert show];
//    }
//	[self dismissModalViewControllerAnimated:YES];
//}

@end

//
//  AppDelegate.m
//  PhotoBrowser
//
//  Created by ukv on 4/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"

#import "Browser.h"

@implementation AppDelegate

@synthesize window = _window;
@synthesize viewController = _viewController;
@synthesize photos = _photos;

- (void)dealloc
{
    [_window release];
    [_viewController release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    // Override point for customization after application launch.
        
    NSMutableArray *photos = [[NSMutableArray alloc] init];
    for (int i=1; i<=14; ++i) {
//        Photo *photo = [Photo photoWithFilePath:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat: @"%d", i + 1] ofType:@"jpg"]];
        Photo *photo = [Photo photoWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"ftp://127.0.0.1/Downloads/%d.jpg", i]]];

        [photos addObject:photo];
    }
    self.photos = photos;
    Browser *browser = [[Browser alloc] initWithDelegate:self];
//    self.viewController = [[[ViewController alloc] initWithNibName:@"ViewController" bundle:nil] autorelease];
    self.viewController = (UIViewController *)[[[UINavigationController alloc] initWithRootViewController:browser] autorelease];
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (NSUInteger)numberOfPhotosOnPage:(Browser *)browser {
    return 9;
}

- (NSUInteger)numberOfPhotos:(Browser *)browser {
    return _photos.count;
}

- (id<PhotoDelegate>)browser:(Browser *)browser photoAtIndex:(NSUInteger)index {
//    NSLog(@"Appdelgate::browser: ");
    if(index < _photos.count)
        return [_photos objectAtIndex:index];
    
    return nil;
}

@end

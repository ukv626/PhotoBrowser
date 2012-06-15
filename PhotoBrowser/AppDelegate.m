    //
//  AppDelegate.m
//  PhotoBrowser
//
//  Created by ukv on 4/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"

#import "BaseDriver.h"
#import "ConnectionsList.h"
#import "DirectoryList.h"
#import "Downloads.h"

@implementation AppDelegate

@synthesize window = _window;
//@synthesize viewController = _viewController;
@synthesize tabBarController = _tabBarController;

/*
+ (void)initialize
// Set up our default preferences.  We can't do this in -applicationDidFinishLaunching: 
// because it's too late; the view controller's -viewDidLoad method has already run 
// by the time applicationDidFinishLaunching: is called.
{
    if ([self class] == [AppDelegate class]) {
        NSString *      initialDefaultsPath;
        NSDictionary *  initialDefaults;
        
        initialDefaultsPath = [[NSBundle mainBundle] pathForResource:@"InitialDefaults" ofType:@"plist"];
        assert(initialDefaultsPath != nil);
        
        initialDefaults = [NSDictionary dictionaryWithContentsOfFile:initialDefaultsPath];
        assert(initialDefaults != nil);
        
        // If we're running on the device certain defaults don't make any sense 
        // (specifically, the upload defaults, which reference localhost), so 
        // we nix them.
        
#if ! TARGET_IPHONE_SIMULATOR
        {
            NSMutableDictionary *   initialDefaultsChanged;
            
            initialDefaultsChanged = [initialDefaults mutableCopy];
            assert(initialDefaultsChanged != nil);
            
            [initialDefaultsChanged setObject:@"" forKey:@"URLText"];
            
            initialDefaults = initialDefaultsChanged;
        }
#endif
        
        [[NSUserDefaults standardUserDefaults] registerDefaults:initialDefaults];
    }
}
*/

- (void)dealloc
{
    [_window release];
    [_tabBarController release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    /*
     if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
     self.viewController = [[[ViewController alloc] initWithNibName:@"ViewController_iPhone" bundle:nil] autorelease];
     } else {
     self.viewController = [[[ViewController alloc] initWithNibName:@"ViewController_iPad" bundle:nil] autorelease];
     }
     */
    
    // Transfers
    Downloads *downloads = [[Downloads alloc] init];
    UINavigationController *downloadsNav = [[UINavigationController alloc] initWithRootViewController:downloads];
    
    UIViewController *remote = [[UINavigationController alloc] initWithRootViewController:[[ConnectionsList alloc] initWithDownloads:downloads]];
    
    // Local
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *dir = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Downloads"];
    
    BaseDriver *localDriver = [[BaseDriver alloc] initWithURL:[NSURL fileURLWithPath:dir]];
    UIViewController *local = [[UINavigationController alloc] 
                       initWithRootViewController:[[DirectoryList alloc] initWithDriver:localDriver]];
    [localDriver release];
    local.title = @"Local 2";
    
    
    
    // Settings
//    UIViewController *settingsController = [[UIViewController alloc] init];

    self.tabBarController = [[UITabBarController alloc] init];
    self.tabBarController.viewControllers = [NSArray arrayWithObjects:remote, 
                                             local, downloadsNav, nil]; //  settingsController, nil];
    [remote release];
    [local release];
    [downloads release];
//    [settingsController release];

    self.window.rootViewController = self.tabBarController;
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


@end

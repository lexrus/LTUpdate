//
//  LTAppDelegate.m
//  LTUpdate Demo
//
//  Created by Lex on 18/2/13.
//  Copyright (c) 2013 Lex Tang. All rights reserved.
//

#import "LTAppDelegate.h"
#import "LTUpdate.h"
//#import "MBAlertView.h"

@implementation LTAppDelegate

- (void)dealloc
{
    [_window release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    UIViewController *rootViewController = [[UIViewController alloc] init];
    rootViewController.view.backgroundColor = [UIColor colorWithWhite:0.298 alpha:1.000];
    self.window.rootViewController = rootViewController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
//    [[LTUpdate shared] updateAndPush:LTUpdateDaily]; return;
    
    [[LTUpdate shared] update:LTUpdateHourly
                     complete:^(BOOL isNewVersionAvailable, LTUpdateVersionDetails *versionDetails) {

//*// [TIP] Remove the first slash to toggle block comments if you'd like to use MBAlertView.
                         if (isNewVersionAvailable) {
                             NSLog(@"New version %@ released on %@.", versionDetails.version, versionDetails.releaseDate);
                             NSLog(@"The app is about %@", humanReadableFileSize(versionDetails.fileSizeBytes));
                             NSLog(@"Release notes:\n%@", versionDetails.releaseNotes);
                             [[LTUpdate shared] alertLatestVersion:LTUpdateOption | LTUpdateSkip];
                         } else {
                             NSLog(@"You App is up to date.");
                         }
/*/
                         if (isNewVersionAvailable) {
                             NSString *text = [NSString stringWithFormat:@"%@\n\n%@", LTI18N(@"A new version is available!"), versionDetails.releaseNotes];
                             MBAlertView *alertView = [MBAlertView alertWithBody:text
                                            cancelTitle:LTI18N(@"Remind Me Later") cancelBlock:nil];
                             [alertView addButtonWithText:LTI18N(@"Update") type:MBAlertViewItemTypeDefault block:^{
                                 [[LTUpdate shared] openAppStore];
                             }];
                             alertView.bodyFont = [UIFont systemFontOfSize:11];
                             [alertView addToDisplayQueue];
                         } else {
                             NSLog(@"You App is up to date.");
                         }
//*/
                     }];
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
//    [[LTUpdate shared] reduceNotification:notification then:LTUpdateNotifyThenAlert];
}

@end

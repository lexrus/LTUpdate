//
//  LTAppDelegate.m
//  LTUpdate Demo
//
//  Created by Lex on 18/2/13.
//  Copyright (c) 2013 Lex Tang. All rights reserved.
//

#import "LTAppDelegate.h"
#import "LTUpdate.h"

@implementation LTAppDelegate

- (void)dealloc
{
    [_window release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
//    [[LTUpdate shared] clearSkippedVersion];
    [[LTUpdate shared] update:LTUpdateDaily
                     complete:^(BOOL isNewVersionAvailable, LTUpdateVersionDetails *versionDetails) {

                         if (isNewVersionAvailable) {
                             NSLog(@"New version available.");
                             NSLog(@"Version %@ published on %@.", versionDetails.version, versionDetails.releaseDate);
                             NSLog(@"The app is about %@", humanReadableFileSize(versionDetails.fileSizeBytes));
                             [[LTUpdate shared] alertLatestVersion:LTUpdateOption | LTUpdateSkip];
                         } else {
                             NSLog(@"You App is up to date.");
                         }

                     }];
}

@end

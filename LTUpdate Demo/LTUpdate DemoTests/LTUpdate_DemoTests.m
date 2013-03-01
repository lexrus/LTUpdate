//
//  LTUpdate_DemoTests.m
//  LTUpdate DemoTests
//
//  Created by Lex on 18/2/13.
//  Copyright (c) 2013 Lex Tang. All rights reserved.
//

#import "LTUpdate_DemoTests.h"
#import "LTUpdate.h"

@implementation LTUpdate_DemoTests

- (void)setUp {
    [super setUp];
    STAssertFalse([kAppVersion() compare:@"0.0" options:NSNumericSearch] == NSOrderedSame,
    @"App version MUST be greater then zero.");

    STAssertNotNil(kAppName(), @"App display name should not be nil.");
}

- (void)tearDown {
    // Tear-down code here.

    [super tearDown];
}

- (void)testAppStoreID {
    long appStoreID = [[LTUpdate shared] appStoreID];
    STAssertTrue(appStoreID - 361309726 == 0, @"AppStoreID must be fill in <project_name>-Info.plist");
}

- (void)testVersionSkip {
    [[LTUpdate shared] skipVersion:@"0.1"];
    STAssertTrue([[LTUpdate shared] isVersionSkipped:@"0.1"], @"Version 0.1 must be skipped.");
    [[LTUpdate shared] clearSkippedVersion];
    STAssertFalse([[LTUpdate shared] isVersionSkipped:@"0.1"], @"SkippedVersion must be cleared.");
}

- (void)testUpdateVersion {
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    [[LTUpdate shared] update:LTUpdateHourly
                     complete:^(BOOL isNewVersionAvailable, LTUpdateVersionDetails *versionDetails) {

                         if (isNewVersionAvailable) {

                             STAssertTrue([versionDetails.version compare:@"0.0" options:NSNumericSearch] == NSOrderedDescending,
                             @"App Store version should be greater than zero.");
                             STAssertNotNil(versionDetails.releaseNotes, @"Release notes should not be nil.");
                             STAssertTrue(versionDetails.fileSizeBytes > 0, @"File size should be greater than zero.");

                             NSString *readableFileSize = humanReadableFileSize(versionDetails.fileSizeBytes);
                             STAssertTrue(readableFileSize && readableFileSize.length > 2, @"Human readable file size should not be empty.");
                             STAssertTrue(versionDetails.releaseDate.timeIntervalSince1970 > 0, @"Release date should be valid.");

                         } else {

                             STAssertNil(versionDetails, @"Version details must be nil while there is no new version.");

                         }

                         dispatch_semaphore_signal(semaphore);
                     }];

    while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW))
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];
    dispatch_release(semaphore);
}

@end

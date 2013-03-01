//
//  LTUpdate.h
//  LTUpdate
//
//  Created by Lex Tang on 18/2/13.
//
//  The MIT License (MIT)
//  Copyright © 2013 Lex Tang, http://LexTang.com
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the “Software”), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import <Foundation/Foundation.h>
#import <Availability.h>

#ifndef lt_retain
#if __has_feature(objc_arc)
#define lt_retain self
#define lt_dealloc self
#define release self
#define autorelease self
#else
#define lt_retain retain
#define lt_dealloc dealloc
#define __bridge
#endif
#endif

#if (!__has_feature(objc_arc)) || \
(defined __IPHONE_OS_VERSION_MIN_REQUIRED && \
__IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_5_0)
#undef weak
#define weak unsafe_unretained
#undef __weak
#define __weak __unsafe_unretained
#endif


static NSString *kAppVersion() {
    static NSString *appVersion;
    static dispatch_once_t versionToken;
    dispatch_once(&versionToken, ^{
        appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    });
    return appVersion;
}

static NSString *kAppName() {
    static NSString *appName;
    static dispatch_once_t nameToken;
    dispatch_once(&nameToken, ^{
        appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    });
    return appName;
}

static NSString *humanReadableFileSize(unsigned long long int size) {
    NSString *sizeTypeW = @"bytes";
    float working = 0;

    if (size < 1) {
        return @"0KB";
    } else {
        if (size > 1024) {
            working = size / 1024.;
            sizeTypeW = @"KB";
        }
        if (working > 1024) {
            working = working / 1024.;
            sizeTypeW = @"MB";
        }
    }
    return [NSString stringWithFormat:@"%.2f%@", working, sizeTypeW];
}

static NSString *LTI18N(NSString *key) {
    NSString *localizedString = NSLocalizedStringFromTable(key, @"LTUpdate", nil);
    return localizedString ? localizedString : @"";
}


@interface LTUpdateVersionDetails : NSObject<NSCopying>

@property(nonatomic, strong) NSString *version;
@property(nonatomic, strong) NSString *releaseNotes;
@property(nonatomic, strong) NSDate *releaseDate;
@property(nonatomic, assign) long long fileSizeBytes;

@end


typedef NS_ENUM(uint, LTUpdateOptions)
{
    LTUpdateOption,
    LTUpdateForce,
    LTUpdateSkip
};

typedef NS_ENUM(uint, LTUpdateNotifyActions)
{
    LTUpdateNotifyOpenAppStore,
    LTUpdateNotifyThenAlert,
    LTUpdateNotifyDoNothing
};

typedef NS_ENUM(uint, LTUpdatePeroid)
{
    LTUpdateHourly,
    LTUpdateDaily,
    LTUpdateWeekly,
    LTUpdateMonthly
};

#ifndef LTUpdateBlocks
#define LTUpdateBlocks
typedef void(^LTUpdateCallback)(BOOL isNewVersionAvailable, LTUpdateVersionDetails *versionDetails);
#endif


@interface LTUpdate : NSObject

@property(nonatomic, strong) LTUpdateVersionDetails *latestVersion;
@property(nonatomic, assign, readonly) long appStoreID;
@property(nonatomic, strong) LTUpdateCallback completionBlock;

+ (id)shared;

- (void)__attribute__((unused)) update;
- (void)__attribute__((unused)) update:(LTUpdateCallback)callback;
- (void)update:(LTUpdatePeroid)peroid complete:(LTUpdateCallback)callback;

- (BOOL)isVersionSkipped:(NSString *)version;
- (void)skipVersion:(NSString *)version;
- (void)clearSkippedVersion;

- (void)__attribute__((unused)) alertLatestVersion:(LTUpdateOptions)alertOptions;

- (void)__attribute__((unused)) updateAndPush;
- (void)updateAndPush:(LTUpdatePeroid)peroid;
- (void)__attribute__((unused)) pushLatestVersion;
- (void)pushLatestVersion:(UILocalNotification*)localNotification;
- (void)__attribute__((unused)) reduceNotification:(UILocalNotification*)notification;
- (void)reduceNotification:(UILocalNotification*)notification then:(LTUpdateNotifyActions)action;

- (void)openAppStore;

@end

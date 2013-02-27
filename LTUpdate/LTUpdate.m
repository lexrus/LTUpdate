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

#import "LTUpdate.h"

#define kAppStoreFormat @"http://itunes.apple.com/app/id%ld"
#define kiTunesAPILookUpFormat @"http://itunes.apple.com/lookup?id=%ld"
// Alternative URL:
// @define kiTunesLookUpFormat @"http://ax.itunes.apple.com/WebObjects/MZStoreServices.woa/wa/wsLookup?id=%ld"


static int kDailyDuration = 86400;
static int kWeeklyDuration = 604800;
static int kMonthlyDuration = 2592000;

static dispatch_queue_t get_update_queue() {
    static dispatch_once_t updateQueueToken;
    static dispatch_queue_t _updateQueue;

    dispatch_once(&updateQueueToken, ^{
        _updateQueue = dispatch_queue_create("com.lextang.update", NULL);
    });
    return _updateQueue;
};

id LTJSONDecode(NSData *data, NSError **error) {
    id JSON = nil;

    id _targetClass = data;
    SEL _targetSelector = NSSelectorFromString(@"objectFromJSONDataWithParseOptions:error");
    BOOL hasJSONKit = YES;

    if (!(_targetSelector && [data respondsToSelector:_targetSelector])) {
        _targetSelector = NSSelectorFromString(@"JSONObjectWithData:options:error:");
        _targetClass = NSClassFromString(@"NSJSONSerialization");
        hasJSONKit = NO;
        if (!_targetClass) return nil;
    }

    NSInvocation *invocation = [NSInvocation
            invocationWithMethodSignature:[_targetClass methodSignatureForSelector:_targetSelector]];
    invocation.target = _targetClass;
    invocation.selector = _targetSelector;

    if (!hasJSONKit)
        [invocation setArgument:&data atIndex:2];
    NSUInteger optionFlags = 0;
    [invocation setArgument:&optionFlags atIndex:hasJSONKit ? 2 : 3];
    if (error != NULL) {
        [invocation setArgument:&error atIndex:hasJSONKit ? 3 : 4];
    }

    [invocation invoke];
    [invocation getReturnValue:&JSON];
    return JSON;
}

NSDate *parseRFC3339Date(NSString *dateString) {
    NSDateFormatter *rfc3339TimestampFormatterWithTimeZone = [[NSDateFormatter alloc] init];
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [rfc3339TimestampFormatterWithTimeZone setLocale:locale];
    [rfc3339TimestampFormatterWithTimeZone setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];

    NSDate *theDate = nil;
    NSError *error = nil;
    if (![rfc3339TimestampFormatterWithTimeZone getObjectValue:&theDate forString:dateString range:nil error:&error]) {
    }

    [locale release];
    locale = nil;
    [rfc3339TimestampFormatterWithTimeZone release];
    rfc3339TimestampFormatterWithTimeZone = nil;
    return theDate;
}

@implementation LTUpdateVersionDetails

@end


@interface LTUpdate () <UIAlertViewDelegate>

@end


@implementation LTUpdate {
    __unsafe_unretained LTUpdateCallback _completionBlock;
}

@synthesize latestVersion = _latestVersion;
@synthesize completionBlock = _completionBlock;

static long _appStoreID;

+ (id)shared {
    static LTUpdate *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[LTUpdate alloc] init];
        _appStoreID = [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"APP_STORE_ID"] longValue];
    });
    return instance;
}

- (long)appStoreID {
    return _appStoreID;
}

- (void)update {
    [self update:^(BOOL isNewVersionAvailable, LTUpdateVersionDetails *versionDetails) {
        [self alertLatestVersion:LTUpdateOption | LTUpdateSkip];
    }];
}

- (void)update:(LTUpdateCallback)callback {
    [self update:LTUpdateDaily complete:callback];
}

- (void)update:(LTUpdatePeroid)peroid complete:(LTUpdateCallback)callback {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
    if (callback)
        self.completionBlock = callback;
#pragma clang diagnostic pop

    double lastUpdateInterval = [self lastUpdateInterval];
    double timestamp = [[NSDate date] timeIntervalSince1970];

    if ((peroid & LTUpdateDaily && timestamp - lastUpdateInterval < kDailyDuration) ||
            (peroid & LTUpdateWeekly && timestamp - lastUpdateInterval < kWeeklyDuration) ||
            (peroid & LTUpdateMonthly && timestamp - lastUpdateInterval < kMonthlyDuration)) {
        self.completionBlock(NO, nil);
        return;
    }

    __weak __typeof (&*self) weakSelf = self;
    dispatch_async(get_update_queue(), ^{
        __strong __typeof (&*weakSelf) strongSelf = weakSelf;
        if (!strongSelf.completionBlock) return;

        [strongSelf parseJSON:[strongSelf fetchJSON]];
        if ([strongSelf latestVersion]) {
            if (strongSelf.completionBlock)
                dispatch_sync(dispatch_get_main_queue(), ^{
                    strongSelf.completionBlock(YES, [strongSelf latestVersion]);
                });
        } else {
            dispatch_sync(dispatch_get_main_queue(), ^{
                strongSelf.completionBlock(NO, nil);
            });
        }
    });
}

#pragma mark - JSON

- (NSData *)fetchJSON {
    NSString *urlString = [NSString stringWithFormat:kiTunesAPILookUpFormat, [self appStoreID]];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url
                                             cachePolicy:NSURLRequestReloadRevalidatingCacheData
                                         timeoutInterval:30];
    NSError *error = nil;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:NULL error:&error];
    [urlString release];
    urlString = nil;
    if (!error) {
        [self setLastUpdateInterval];
        return responseData;
    }
    return nil;
}

- (void)parseJSON:(NSData *)jsonData {
    NSError *error = nil;
    id json = LTJSONDecode(jsonData, &error);
    if (!error && [json isKindOfClass:[NSDictionary class]]) {
        NSArray *results = [json objectForKey:@"results"];
        if (results && [results isKindOfClass:[NSArray class]] && [results count] > 0) {
            NSDictionary *versionDetail = [results[0] copy];
            if (versionDetail && [versionDetail isKindOfClass:[NSDictionary class]]) {
                NSString *newVersion = [versionDetail objectForKey:@"version"];
                NSString *releaseNotes = [versionDetail objectForKey:@"releaseNotes"];
                NSString *releaseDate = [versionDetail objectForKey:@"releaseDate"];
                NSString *fileSizeBytes = [versionDetail objectForKey:@"fileSizeBytes"];
                if (newVersion &&
                        [newVersion isKindOfClass:[NSString class]] &&
                        [newVersion compare:kAppVersion() options:NSNumericSearch] == NSOrderedDescending &&
                        ![self isVersionSkipped:newVersion]) {
                    _latestVersion = [[LTUpdateVersionDetails alloc] init];
                    _latestVersion.version = [newVersion copy];
                    if (releaseNotes && [releaseNotes length] > 0) {
                        _latestVersion.releaseNotes = [releaseNotes copy];
                    }
                    if (releaseDate) {
                        _latestVersion.releaseDate = parseRFC3339Date(releaseDate);
                    }
                    if (fileSizeBytes && [fileSizeBytes longLongValue] > 0) {
                        _latestVersion.fileSizeBytes = [fileSizeBytes longLongValue];
                    }
                } else {
                    _latestVersion = nil;
                }
            }
        }
    }
}

#pragma mark - Update interval

- (double)lastUpdateInterval {
    return [[NSUserDefaults standardUserDefaults] doubleForKey:@"LTLastUpdateDate"];
}

- (void)setLastUpdateInterval {
    double timestamp = [[NSDate date] timeIntervalSince1970];
    [[NSUserDefaults standardUserDefaults] setDouble:timestamp forKey:@"LTLastUpdateDate"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Skipped version

- (NSString *)versionSkipped {
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"LTSkippedVersion"];
}

- (void)setVersionSkipped:(NSString *)version {
    [[NSUserDefaults standardUserDefaults] setObject:version forKey:@"LTSkippedVersion"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)isVersionSkipped:(NSString *)version {
    return [version compare:[self versionSkipped] options:NSNumericSearch] == NSOrderedSame;
}

- (void)skipVersion:(NSString *)version {
    [self setVersionSkipped:version];
}

- (void)clearSkippedVersion {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"LTSkippedVersion"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Default Alert

- (void)__attribute__((unused)) alertLatestVersion:(LTUpdateOptions)alertOptions {
    UIAlertView *alertView = [[UIAlertView alloc] init];
    [alertView setTitle:LTI18N(@"A new version is available!")];
    [alertView setMessage:[NSString stringWithFormat:LTI18N(@"%@ %@ is now available. You have %@. Would you like to download(%@) it now?"), kAppName(), self.latestVersion.version, kAppVersion(), humanReadableFileSize(self.latestVersion.fileSizeBytes)]];

    [alertView addButtonWithTitle:LTI18N(@"Update")];

    if (alertOptions & LTUpdateForce) {
        
    } else {
        if (alertOptions & LTUpdateSkip) {
            [alertView addButtonWithTitle:LTI18N(@"Skip This Version")];
        }
        [alertView addButtonWithTitle:LTI18N(@"Remind Me Later")];
    }

    [alertView setDelegate:self];
    [alertView show];
    [alertView release];
    alertView = nil;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        NSString *appStoreURL = [NSString stringWithFormat:kAppStoreFormat, [self appStoreID]];
        NSURL *url = [NSURL URLWithString:appStoreURL];
        [[UIApplication sharedApplication] openURL:url];
    } else if ([[alertView buttonTitleAtIndex:buttonIndex]
            isEqualToString:LTI18N(@"Skip This Version")]) {
        [self skipVersion:[[self latestVersion] version]];
    }
}

#pragma mark - Open AppStore

- (void)openAppStore
{
    NSString *appStoreURL = [NSString stringWithFormat:kAppStoreFormat, [self appStoreID]];
    NSURL *url = [NSURL URLWithString:appStoreURL];
    [[UIApplication sharedApplication] openURL:url];
}


@end

# LTUpdate


### Features
* ARC/MRC compatible
* Block based interface
* GCD
* Update period control
* “Skip This Version”
* Multilingual
* Version details
* Customizable alert view

### Requirements
LTUpdate requires iOS 4.3 or newer.

It's compatible with both ARC and MRC. But MRC mode is not well tested yet.

[JSONKit](https://github.com/johnezang/JSONKit) is required while you are building for iOS 4.3.


### Usage
Download the zip file and unzip it. Drag & drop LTUpdate/LTUpdate folder to your project.

Or install with [CocoaPods](https://github.com/CocoaPods/CocoaPods):
```pod 'LTUpdate', '~>0.0.1'```

After that, add ```#import "LTUpdate.h"``` to AppDelegate.m.

Invoke the update method in applicationDidBecomeActive:

```[[LTUpdate shared] update];```

LTUpdate will check new verison from iTunes API. And prompt the user to update if there is a new version available.

If you need more control:

```[[LTUpdate shared] update:LTUpdateDaily
                     complete:^(BOOL isNewVersionAvailable, LTUpdateVersionDetails *versionDetails) {

                         if (isNewVersionAvailable) {
                             NSLog(@"New version %@ published on %@.", versionDetails.version, versionDetails.releaseDate);
                             NSLog(@"The app is about %@", humanReadableFileSize(versionDetails.fileSizeBytes));
                             NSLog(@"Release notes:\n%@", versionDetails.releaseNotes);
                             // Your alert view here
                             [[LTUpdate shared] alertLatestVersion:LTUpdateOption | LTUpdateSkip];
                         } else {
                             NSLog(@"You App is up to date.");
                         }

                     }];```

A customized example shows you how to replace the alert view with other open source alternatives.

<example placeholder>


```2013-02-27 18:03:50.253 LTUpdate Demo[6285:c07] New version 1.7.1 published on 2010-04-01 08:36:57 +0000.
2013-02-27 18:03:50.253 LTUpdate Demo[6285:c07] The app is about 245.31MB
2013-02-27 18:03:50.253 LTUpdate Demo[6285:c07] Release notes:
In this release Pages for iOS is updated for improved compatibility with Microsoft Word and Pages for Mac.
...
Pages 1.7.1 resolves issues related to Accessibility settings.```

Also clear skipped version at any time:
```[[LTUpdate shared] clearSkippedVersion];``` 


### AppStore Submissions

The AppStore reviewer will not see the alert. Because the submitted version is always greater than the online version in AppStore.


### Testing & Building the demo

Testing coverage is about 70% exclude UI functions.

Install [JSONKit](https://github.com/johnezang/JSONKit) before build.
```git submodule init
git submodule update```


### License
This code is distributed under the terms and conditions of the MIT license. See LTUpdate.h for details.
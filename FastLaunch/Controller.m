//
//  Controller.m
//  FastLaunch
//
//  Created by Sergey Galan.
//  Copyright © 2020-2025 Sergey Galan. All rights reserved.
//


#import "Controller.h"
#import "FastLaunchJob.h"
#import "DockProgressBarRed.h"
#import "DockProgressBarBlue.h"
#import <Quartz/Quartz.h>
#import <UserNotifications/UserNotifications.h>

#define FILEMGR     [NSFileManager defaultManager]
#define DEFAULTS    [NSUserDefaults standardUserDefaults]

#ifdef DEBUG
    #define PLog(...) NSLog(__VA_ARGS__)
#else
    #define PLog(...)
#endif

@import AVFoundation;

static const NSInteger detailsHeight = 310;
static NSString * const kPrefsPlistPath = @"/Preferences/org.SerhiiHalan.SettingsFastLaunch.plist";

@interface Controller () <UNUserNotificationCenterDelegate>
{
    IBOutlet NSProgressIndicator *progressBarIndicator;
    IBOutlet NSWindow *FastLaunchWindow;
    IBOutlet NSButton *CancelButton;
    IBOutlet NSTextField *MessageTextFieldName;
    IBOutlet NSTextField *MessageTextFieldProgress;
    IBOutlet NSTextField *MessageTextFieldFPS;
    IBOutlet NSTextField *MessageTextFieldSize;
    IBOutlet NSTextField *MessageTextFieldDuration;
    IBOutlet NSTextField *MessageTextFieldTime;
    IBOutlet NSTextField *MessageTextFieldSpeed;
    IBOutlet NSTextField *MessageTextFieldInfo;
    IBOutlet NSTextField *MessageTextFieldMediaInfo;
    IBOutlet NSButton *DetailsTriangle;
    IBOutlet NSTextField *DetailsLabel;
    IBOutlet NSButton *buttonClick;
    IBOutlet NSButton *savePlist1;
    IBOutlet NSButton *savePlist1a;
    IBOutlet NSButton *savePlist1b;
    IBOutlet NSButton *savePlist3;
    IBOutlet NSButton *savePlist4;
    IBOutlet NSButton *FolderPicker1;
    IBOutlet NSButton *FolderPicker2;
    IBOutlet NSButton *Interlaced;
    IBOutlet NSButton *Preset;
    IBOutlet NSImageView *myImageView;
    IBOutlet NSProgressIndicator *ProgressIndicator;
    IBOutlet NSProgressIndicator *ProgressIndicatorPreset;
    IBOutlet id FolderLabel1;
    IBOutlet id FoldernameLabel1;
    IBOutlet id FolderLabel2;
    IBOutlet id FoldernameLabel2;

    // Menu items
    IBOutlet NSMenuItem *openRecentMenuItem;
    IBOutlet NSMenu *windowMenu;
    IBOutlet NSMenu *fileMenu;
    IBOutlet NSMenu *viewMenu;

    NSTextView *outputTextView;

    NSTask *task;

    NSPipe *inputPipe;
    NSFileHandle *inputWriteFileHandle;
    NSPipe *outputPipe;
    NSFileHandle *outputReadFileHandle;

    NSMutableArray <NSString *> *arguments;
    NSArray <NSString *> *interpreterArgs;
    NSString *stdinString;

    NSString *interpreterPath;
    NSString *scriptDropPath;
    NSString *scriptStartPath;

    BOOL isDroppable;
    BOOL remainRunning;
    BOOL acceptsFiles;
    BOOL acceptsText;
    BOOL promptForFileOnLaunch;
    BOOL statusItemUsesSystemFont;
    BOOL statusItemIconIsTemplate;
    BOOL runInBackground;
    BOOL isService;
    BOOL sendsNotifications;
    BOOL acceptAnyDroppedItem;
    BOOL acceptDroppedFolders;

    NSImage *statusItemImage;

    BOOL isTaskRunning;
    BOOL outputEmpty;
    BOOL hasTaskRun;
    BOOL hasFinishedLaunching;

    NSString *remnants;

    NSMutableArray <FastLaunchJob *> *jobQueue;

    // Новые поля
    NSMutableDictionary *settingsCache;
    BOOL settingsDirty;
    NSString *tempFolderPath;
}

@property (unsafe_unretained) IBOutlet NSArrayController *testArray1;
@property (unsafe_unretained) IBOutlet NSArrayController *testArray2;
@property (unsafe_unretained) IBOutlet NSArrayController *testArray3;
@property (unsafe_unretained) IBOutlet NSArrayController *testArray4;
@property (unsafe_unretained) IBOutlet NSArrayController *testArray5;
@property (unsafe_unretained) IBOutlet NSArrayController *testArray6;
@property (unsafe_unretained) IBOutlet NSArrayController *testArray7;
@property (unsafe_unretained) IBOutlet NSArrayController *testArray8;
@property (unsafe_unretained) IBOutlet NSArrayController *testArray9;
@property (unsafe_unretained) IBOutlet NSArrayController *testArray10;
@property (unsafe_unretained) IBOutlet NSArrayController *testArray11;
@property (unsafe_unretained) IBOutlet NSArrayController *testArray12;
@property (nonatomic, strong) NSString *currentlySelectedPort1;
@property (nonatomic, strong) NSString *currentlySelectedPort2;
@property (nonatomic, strong) NSString *currentlySelectedPort3;
@property (nonatomic, strong) NSString *currentlySelectedPort4;
@property (nonatomic, strong) NSString *currentlySelectedPort5;
@property (nonatomic, strong) NSString *currentlySelectedPort6;
@property (nonatomic, strong) NSString *currentlySelectedPort7;
@property (nonatomic, strong) NSString *currentlySelectedPort8;
@property (nonatomic, strong) NSString *currentlySelectedPort9;
@property (nonatomic, strong) NSString *currentlySelectedPort10;
@property (nonatomic, strong) NSString *currentlySelectedPort11;
@property (nonatomic, strong) NSString *currentlySelectedPort12;
@property (retain) NSString *plistFileName;
@property (retain) NSString *InterlacedKey;
@property (retain) NSString *WaitKey;
@property (retain) NSString *XMLfileKey;
@property (retain) NSString *ServerKey;
@property (retain) NSString *UserKey;
@property (retain) NSString *CustomRes;
@property (retain) NSString *CustomVBit;
@property (retain) NSString *PassKey;
@property (retain) NSString *Folder1;
@property (retain) NSString *Folder2;
@property (retain) IBOutlet NSTextField *ServerTextField;
@property (retain) IBOutlet NSTextField *UserTextField;
@property (retain) IBOutlet NSTextField *CustomResolution;
@property (retain) IBOutlet NSTextField *CustomVBitRate;
@property (retain) IBOutlet NSSecureTextField *PassTextField;
@property (retain) NSString *SecondsString;
@property (retain) NSString *SecondsStringOld;
@property (retain) NSString *ProgressString;
@property (retain) NSString *ProgressStringOld;
@property (retain) NSString *FileString;
@property (retain) NSString *OnlyString;
@property (assign) IBOutlet NSView *view;

@end

#pragma mark - Private helpers (prototypes)
@interface Controller (Private)
- (void)loadSettingsIfNeeded;
- (void)saveSettingsIfNeeded;
- (void)updateSettingForKey:(NSString *)key value:(id)value;
- (NSString *)preferencesPlistPath;
- (void)configureNotificationsIfNeeded;
- (void)setControlsEnabled:(BOOL)enabled;
- (void)applyProgressFilterForMode:(NSString *)mode;
- (void)updateProgressBarWithPercent:(double)percent mode:(NSString *)mode;
- (NSArray<NSString *> *)safePathsFromOpenPanelURLs:(NSArray<NSURL *> *)urls;
- (NSArray<NSString *> *)safePathsFromPasteboard:(NSPasteboard *)pboard;
- (NSString *)cleanedLine:(NSString *)line;
- (void)handleParsedLine:(NSString *)line;
- (void)requestKeychainPasswordIfNeeded;
@end

@implementation Controller

- (instancetype)init {
    self = [super init];
    if (self) {
        arguments = [NSMutableArray array];
        outputEmpty = YES;
        jobQueue = [NSMutableArray array];
        settingsCache = nil;
        settingsDirty = NO;
        tempFolderPath = nil;
    }
    return self;
}

- (void)awakeFromNib {
    [self loadAppSettings];
    [self initialiseInterface];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(taskFinished:)
                                                 name:NSTaskDidTerminateNotification
                                               object:nil];

    [self configureNotificationsIfNeeded];
}

#pragma mark - App Settings

- (void)loadAppSettings {
    NSBundle *bundle = [NSBundle mainBundle];
    scriptDropPath = [bundle pathForResource:@"/scripts/scriptDrop" ofType:nil];
    if (![FILEMGR fileExistsAtPath:scriptDropPath]) {
        NSLog(@"/scripts/scriptDrop missing from application bundle.");
    }

    scriptStartPath = [bundle pathForResource:@"/scripts/scriptStart" ofType:nil];
    if (![FILEMGR fileExistsAtPath:scriptStartPath]) {
        NSLog(@"/scripts/scriptStart missing from application bundle.");
    }

    NSNumber *permissions = @(0755);
    NSDictionary *attributes = @{ NSFilePosixPermissions: permissions };
    [FILEMGR setAttributes:attributes ofItemAtPath:scriptDropPath error:nil];
    [FILEMGR setAttributes:attributes ofItemAtPath:scriptStartPath error:nil];

    interpreterPath = @"/bin/sh";
    remainRunning = YES;
    isDroppable = NO;
    promptForFileOnLaunch = NO;

    acceptsFiles = YES;
    if (acceptsFiles) {
        acceptAnyDroppedItem = YES;
        isDroppable = YES;
    }

    // Prepare a temporary folder once
    tempFolderPath = [[NSTemporaryDirectory() stringByAppendingPathComponent:@"FastLaunch"] copy];
    NSError *dirErr = nil;
    if (![FILEMGR fileExistsAtPath:tempFolderPath]) {
        [FILEMGR createDirectoryAtPath:tempFolderPath withIntermediateDirectories:YES attributes:nil error:&dirErr];
        if (dirErr) {
            NSLog(@"Temp folder create error: %@", dirErr.localizedDescription);
        }
    }
}

#pragma mark - Settings cache

- (NSString *)preferencesPlistPath {
    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
    return [rootPath stringByAppendingPathComponent:kPrefsPlistPath];
}

- (void)loadSettingsIfNeeded {
    if (settingsCache) { return; }
    self.plistFileName = [self preferencesPlistPath];
    NSData *plistData = [NSData dataWithContentsOfFile:self.plistFileName];
    if (!plistData) {
        // Creating a default dictionary
        NSMutableDictionary *root = [NSMutableDictionary dictionary];
        root[@"VEncoder"] = @"H.264 (x264)";
        root[@"AEncoder"] = @"aac";
        root[@"VBitRate"] = @"15000k";
        root[@"Resolution"] = @"1920x1080";
        root[@"Preset"] = @"medium";
        root[@"FrameRate"] = @"25";
        root[@"AspectRatio"] = @"16:9";
        root[@"Chroma"] = @"yuv420p";
        root[@"ABitRate"] = @"192k";
        root[@"Mode"] = @"Encoding and Server";
        root[@"Channels"] = @"2";
        root[@"SampleRate"] = @"48000";
        root[@"Interlaced"] = @NO;
        root[@"Wait"] = @NO;
        root[@"XMLfile"] = @NO;
        root[@"sr"] = @"";
        root[@"un"] = @"";
        root[@"DestinationFolder"] = [self pathForDatafolderDefault1];
        root[@"MonitoringFolder"] = [self pathForDatafolderDefault2];
        settingsCache = root;
        settingsDirty = YES;
        [self saveSettingsIfNeeded];
    } else {
        NSError *error = nil;
        NSPropertyListFormat format;
        id plist = [NSPropertyListSerialization propertyListWithData:plistData options:NSPropertyListMutableContainersAndLeaves format:&format error:&error];
        if (error || ![plist isKindOfClass:[NSDictionary class]]) {
            NSLog(@"Error reading plist: %@", error.localizedDescription);
            settingsCache = [NSMutableDictionary dictionary];
        } else {
            settingsCache = [(NSDictionary *)plist mutableCopy];
        }
    }
}

- (void)saveSettingsIfNeeded {
    if (!settingsDirty || !self.plistFileName) { return; }
    NSError *error = nil;
    NSData *representation = [NSPropertyListSerialization dataWithPropertyList:settingsCache
                                                                        format:NSPropertyListBinaryFormat_v1_0
                                                                       options:0
                                                                         error:&error];
    if (!error) {
        BOOL ok = [representation writeToFile:self.plistFileName atomically:YES];
        if (!ok) {
            NSLog(@"Failed to write plist: %@", self.plistFileName);
        }
    } else {
        NSLog(@"Plist serialization error: %@", error.localizedDescription);
    }
    settingsDirty = NO;
}

- (void)updateSettingForKey:(NSString *)key value:(id)value {
    if (!key) { return; }
    id current = settingsCache[key];
    BOOL changed = (current == nil) ? (value != nil) : ![current isEqual:value];
    if (changed) {
        if (value) {
            settingsCache[key] = value;
        } else {
            [settingsCache removeObjectForKey:key];
        }
        settingsDirty = YES;
    }
}

#pragma mark - Temp and folders

- (NSString *) PathForDeleteFile
{
NSError *error;
    NSString *path = @"/private/tmp/img.png";
    if ([[NSFileManager defaultManager] isDeletableFileAtPath:path]) {
    BOOL success = [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
    if (!success) {
        NSLog(@"%@", error.localizedDescription);
    }
 }
    return path;
}

// Creating a folder and deleting folder contents
- (NSString *) pathForDataFile
{
    BOOL isDir;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *folder = @"/private/tmp/FastLaunch/";
    folder = [folder stringByExpandingTildeInPath];
    NSError *error = nil;
    if(![fileManager fileExistsAtPath:folder isDirectory:&isDir]) {
        if(![fileManager createDirectoryAtPath:folder withIntermediateDirectories:YES attributes:nil error:NULL])
            NSLog(@"Error: Create folder failed %@",folder);
    }
    if (![fileManager removeItemAtPath:folder error:&error]) {
      NSLog(@"[Error] %@ (%@)", error, folder);
  }
if (![fileManager fileExistsAtPath:folder]) {
    [fileManager createDirectoryAtPath:folder
           withIntermediateDirectories:NO
                            attributes:nil
                                 error:&error];

}
     return folder;
}

- (NSString *)pathForDatafolderDefault1 {
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSMoviesDirectory, NSUserDomainMask, YES) firstObject];
    NSString *dataPath = [path stringByAppendingPathComponent:@"/FastLaunch output"];
    if (![FILEMGR fileExistsAtPath:dataPath]) {
        NSError *error = nil;
        [FILEMGR createDirectoryAtPath:dataPath withIntermediateDirectories:NO attributes:nil error:&error];
        if (error) NSLog(@"Create default output folder error: %@", error.localizedDescription);
    }
    return dataPath;
}

- (NSString *)pathForDatafolderDefault2 {
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES) firstObject];
    NSString *dataPath = [path stringByAppendingPathComponent:@"/FastLaunch input"];
    if (![FILEMGR fileExistsAtPath:dataPath]) {
        NSError *error = nil;
        [FILEMGR createDirectoryAtPath:dataPath withIntermediateDirectories:NO attributes:nil error:&error];
        if (error) NSLog(@"Create default input folder error: %@", error.localizedDescription);
    }
    return dataPath;
}

- (NSString *)pathForDatafolder1 {
    NSString *folder = [self.Folder1 stringByExpandingTildeInPath];
    BOOL isDir = NO;
    if (![FILEMGR fileExistsAtPath:folder isDirectory:&isDir]) {
        NSError *error = nil;
        [FILEMGR createDirectoryAtPath:folder withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) NSLog(@"Create folder1 error: %@", error.localizedDescription);
    }
    return folder;
}

- (NSString *)pathForDatafolder2 {
    NSString *folder = [self.Folder2 stringByExpandingTildeInPath];
    BOOL isDir = NO;
    if (![FILEMGR fileExistsAtPath:folder isDirectory:&isDir]) {
        NSError *error = nil;
        [FILEMGR createDirectoryAtPath:folder withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) NSLog(@"Create folder2 error: %@", error.localizedDescription);
    }
    return folder;
}

#pragma mark - Notifications

- (void)configureNotificationsIfNeeded {
    if (!sendsNotifications) { return; }
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    center.delegate = self;
    [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge)
                          completionHandler:^(BOOL granted, NSError * _Nullable error) {
        NSLog(@"Notifications granted: %d, error: %@", granted, error.localizedDescription);
    }];
}

// Show banner even if the application is active
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
    if (@available(macOS 11.0, *)) {
        completionHandler(UNNotificationPresentationOptionBanner | UNNotificationPresentationOptionSound | UNNotificationPresentationOptionList);
    } else {
        // There are no banners on macOS 10.15 - leave the sound (or 0 if you don't need anything).
        completionHandler(UNNotificationPresentationOptionSound);
    }
}

#pragma mark - App Delegate handlers

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    PLog(@"Application did finish launching");
    hasFinishedLaunching = YES;

    // Enable notifications by default (can be replaced with a user setting if necessary)
    sendsNotifications = YES;
}

#pragma mark - UI helpers

- (void)setControlsEnabled:(BOOL)enabled {
    dispatch_async(dispatch_get_main_queue(), ^{
        [CancelButton setEnabled:YES]; // кнопка всегда активна, меняется только название
        [savePlist1 setEnabled:enabled];
        [savePlist1a setEnabled:enabled];
        [savePlist1b setEnabled:enabled];
        [FolderPicker1 setEnabled:enabled];
        [FolderPicker2 setEnabled:enabled];
    });
}

- (void)applyProgressFilterForMode:(NSString *)mode {
    CIFilter *filter = nil;
    if ([mode isEqualToString:@"RED"]) {
        filter = [CIFilter filterWithName:@"CIHueAdjust" withInputParameters:@{@"inputAngle" : @8.5}];
    } else if ([mode isEqualToString:@"BLUE"]) {
        filter = [CIFilter filterWithName:@"CIHueAdjust" withInputParameters:@{@"inputAngle" : @0}];
    } else {
        CIColor *color = [[CIColor alloc] initWithColor:[NSColor colorWithSRGBRed:0.8 green:0.8 blue:0.8 alpha:1]];
        filter = [CIFilter filterWithName:@"CIColorMonochrome"
                      withInputParameters:@{@"inputColor" : color, @"inputIntensity" : @1}];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        progressBarIndicator.contentFilters = filter ? @[filter] : @[];
    });
}

- (void)updateProgressBarWithPercent:(double)percent mode:(NSString *)mode {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self applyProgressFilterForMode:mode];
        [progressBarIndicator setIndeterminate:NO];
        [progressBarIndicator setDoubleValue:percent];
    });
}

#pragma mark - Interface actions

- (IBAction)savePlist1:(id)sender {
    [ProgressIndicator setHidden:NO];
    [ProgressIndicator startAnimation:self];
    
    [self loadSettingsIfNeeded];
    
    NSString *newServer = ([_ServerTextField stringValue] ? [_ServerTextField stringValue] : @"");
    NSString *newUser = ([_UserTextField stringValue] ? [_UserTextField stringValue] : @"");
    NSString *newPass = ([_PassTextField stringValue] ? [_PassTextField stringValue] : @"");
    
    // We update the settings cache only when changes occur.
    [self updateSettingForKey:@"sr" value:newServer];
    [self updateSettingForKey:@"un" value:newUser];
    [self updateSettingForKey:@"XMLfile" value:(self.XMLfileKey ? self.XMLfileKey : @NO)];
    
    // Keychain: We update only if the password has actually changed.
    if (![newPass isEqualToString:self.PassKey]) {
        self.PassKey = newPass;
        NSString * command = [NSString stringWithFormat:@"/usr/bin/security delete-generic-password -a ${USER} -s postftp >/dev/null 2>&1; \
        /usr/bin/security add-generic-password -a ${USER} -s postftp -w %@ >/dev/null 2>&1", self.PassKey];
        NSTask *taskPass = [[NSTask alloc] init];
        [taskPass setLaunchPath:@"/bin/bash"];
        [taskPass setArguments:[NSArray arrayWithObjects: @"-c", command, nil]];
        [taskPass launch];
        newPass = self.PassKey;
    }
    
    [self saveSettingsIfNeeded];
   
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        [NSThread sleepForTimeInterval:0.8];

        dispatch_async(dispatch_get_main_queue(), ^{
            [ProgressIndicator stopAnimation:self];
            [ProgressIndicator setHidden:YES];
        });
    });
}

- (IBAction)savePlist2:(id)sender {
    [ProgressIndicatorPreset setHidden:NO];
    [ProgressIndicatorPreset startAnimation:self];
    
    [self loadSettingsIfNeeded];
    
    // Refreshing the settings cache
    [self updateSettingForKey:@"VEncoder" value:_currentlySelectedPort1];
    [self updateSettingForKey:@"AEncoder" value:_currentlySelectedPort2];
    [self updateSettingForKey:@"VBitRate" value:_currentlySelectedPort3];
    [self updateSettingForKey:@"Resolution" value:_currentlySelectedPort4];
    [self updateSettingForKey:@"Preset" value:_currentlySelectedPort5];
    [self updateSettingForKey:@"FrameRate" value:_currentlySelectedPort6];
    [self updateSettingForKey:@"ABitRate" value:_currentlySelectedPort8];
    [self updateSettingForKey:@"SampleRate" value:_currentlySelectedPort9];
    [self updateSettingForKey:@"Mode" value:_currentlySelectedPort10];
    [self updateSettingForKey:@"Channels" value:_currentlySelectedPort11];
    [self updateSettingForKey:@"AspectRatio" value:_currentlySelectedPort12];
    [self updateSettingForKey:@"Wait" value:(self.WaitKey ? self.WaitKey : @NO)];
    
    if ([_currentlySelectedPort1 isEqual:@"H.264 (x264)"]) {
        [self updateSettingForKey:@"Interlaced" value:(self.InterlacedKey ? self.InterlacedKey : @"0")];
        [self updateSettingForKey:@"Chroma" value:_currentlySelectedPort7];
        [Interlaced setEnabled:YES];
        [Preset setEnabled:YES];
    } else if ([_currentlySelectedPort1 isEqual:@"H.265 (x265)"]) {
        self.InterlacedKey = @"0";
        [self updateSettingForKey:@"Interlaced" value:self.InterlacedKey];
        [self updateSettingForKey:@"Chroma" value:_currentlySelectedPort7];
        [Interlaced setEnabled:NO];
        [Preset setEnabled:YES];
    } else if ([_currentlySelectedPort1 isEqual:@"H.264 Hardware"]) {
        self.InterlacedKey = @"0";
        [self updateSettingForKey:@"Interlaced" value:self.InterlacedKey];
        self.currentlySelectedPort7 = @"yuv420p";
        [self updateSettingForKey:@"Chroma" value:_currentlySelectedPort7];
        [Interlaced setEnabled:NO];
        [Preset setEnabled:NO];
    } else if ([_currentlySelectedPort1 isEqual:@"H.265 Hardware"]) {
        if (![_currentlySelectedPort7 isEqual:@"yuv420p"] && ![_currentlySelectedPort7 isEqual:@"yuv420p10le"]) {
            self.currentlySelectedPort7 = @"yuv420p";
        }
        [self updateSettingForKey:@"Chroma" value:_currentlySelectedPort7];
        self.InterlacedKey = @"0";
        [self updateSettingForKey:@"Interlaced" value:self.InterlacedKey];
        [Interlaced setEnabled:NO];
        [Preset setEnabled:NO];
    }
    
    [self saveSettingsIfNeeded];
    
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        [NSThread sleepForTimeInterval:0.8];
        dispatch_async(dispatch_get_main_queue(), ^{
            [ProgressIndicatorPreset stopAnimation:self];
            [ProgressIndicatorPreset setHidden:YES];
        });
    });
}

- (IBAction)savePlist3:(id)sender {
    BOOL isOff = ([sender state] == NSControlStateValueOff);
    [_CustomResolution setHidden:isOff ? YES : NO];

    if (isOff) {
        if (self.CustomRes != nil && ![self.CustomRes isEqual:self.currentlySelectedPort4]) {
            [ProgressIndicatorPreset setHidden:NO];
            [ProgressIndicatorPreset startAnimation:self];
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
                [NSThread sleepForTimeInterval:0.8];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [ProgressIndicatorPreset stopAnimation:self];
                    [ProgressIndicatorPreset setHidden:YES];
                });
            });

            [self loadSettingsIfNeeded];
            [self updateSettingForKey:@"Resolution" value:self.CustomRes];
            [self saveSettingsIfNeeded];

            self.currentlySelectedPort4 = settingsCache[@"Resolution"];
            [self.testArray4 addObject:@{ @"name" : (self.CustomRes ? self.CustomRes : @"") }];
        } else {
            NSLog(@"invalid parameters: %@", self.plistFileName);
        }
    } else {
        [self loadSettingsIfNeeded];
        self.CustomRes = settingsCache[@"Resolution"];
    }
}

- (IBAction)savePlist4:(id)sender {
    BOOL isOff = ([sender state] == NSControlStateValueOff);
    [_CustomVBitRate setHidden:isOff ? YES : NO];

    if (isOff) {
        if (self.CustomVBit != nil && ![self.CustomVBit isEqual:self.currentlySelectedPort3]) {
            [ProgressIndicatorPreset setHidden:NO];
            [ProgressIndicatorPreset startAnimation:self];
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
                [NSThread sleepForTimeInterval:0.8];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [ProgressIndicatorPreset stopAnimation:self];
                    [ProgressIndicatorPreset setHidden:YES];
                });
            });

            [self loadSettingsIfNeeded];
            [self updateSettingForKey:@"VBitRate" value:self.CustomVBit];
            [self saveSettingsIfNeeded];

            self.currentlySelectedPort3 = settingsCache[@"VBitRate"];
            [self.testArray3 addObject:@{ @"name" : (self.CustomVBit ? self.CustomVBit : @"") }];
        } else {
            NSLog(@"invalid parameters: %@", self.plistFileName);
        }
    } else {
        [self loadSettingsIfNeeded];
        self.CustomVBit = settingsCache[@"VBitRate"];
    }
}

- (IBAction)FolderPicker1:(id)sender {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.canChooseDirectories = YES;
    openPanel.canCreateDirectories = YES;
    openPanel.canChooseFiles = NO;

    if ([openPanel runModal] == NSModalResponseOK) {
        NSString *FolderPath = openPanel.URLs.firstObject.path;
        [FoldernameLabel1 setStringValue:FolderPath];

        [self loadSettingsIfNeeded];
        self.Folder1 = FolderPath;
        if (![self.Folder1 isEqual:self.Folder2]) {
            [self updateSettingForKey:@"MonitoringFolder" value:(self.Folder1 ? self.Folder1 : @"")];
        } else {
            self.Folder1 = settingsCache[@"MonitoringFolder"];
        }
        [self saveSettingsIfNeeded];
    }
}

- (IBAction)FolderPicker2:(id)sender {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.canChooseDirectories = YES;
    openPanel.canCreateDirectories = YES;
    openPanel.canChooseFiles = NO;

    if ([openPanel runModal] == NSModalResponseOK) {
        NSString *FolderPath = openPanel.URLs.firstObject.path;
        [FoldernameLabel2 setStringValue:FolderPath];

        [self loadSettingsIfNeeded];
        self.Folder2 = FolderPath;
        if (![self.Folder1 isEqual:self.Folder2]) {
            [self updateSettingForKey:@"DestinationFolder" value:(self.Folder2 ? self.Folder2 : @"")];
        } else {
            self.Folder2 = settingsCache[@"DestinationFolder"];
        }
        [self saveSettingsIfNeeded];
    }
}

- (IBAction)openFiles:(id)sender {
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    oPanel.allowsMultipleSelection = YES;
    oPanel.canChooseFiles = YES;
    oPanel.canChooseDirectories = acceptDroppedFolders;

    if ([oPanel runModal] == NSModalResponseOK) {
        NSArray<NSString *> *filePaths = [self safePathsFromOpenPanelURLs:oPanel.URLs];
        BOOL success = [self addDroppedFilesJob:filePaths];
        if (!isTaskRunning && success) {
            [self executeScript];
        }
    } else if (!remainRunning) {
        [[NSApplication sharedApplication] terminate:self];
    }
}

- (IBAction)toggleDetails:(id)sender {
    NSRect winRect = [FastLaunchWindow frame];
    NSSize minSize = [FastLaunchWindow minSize];
    NSSize maxSize = [FastLaunchWindow maxSize];

    if ([sender state] == NSControlStateValueOff) {
        winRect.origin.y += detailsHeight;
        winRect.size.height -= detailsHeight;
        minSize.height -= detailsHeight;
        maxSize.height -= detailsHeight;
    } else {
        winRect.origin.y -= detailsHeight;
        winRect.size.height += detailsHeight;
        minSize.height += detailsHeight;
        maxSize.height += detailsHeight;
    }

    [DEFAULTS setBool:([sender state] == NSControlStateValueOn) forKey:@"UserShowDetails"];
    [FastLaunchWindow setMinSize:minSize];
    [FastLaunchWindow setMaxSize:maxSize];
    [FastLaunchWindow setShowsResizeIndicator:([sender state] == NSControlStateValueOn)];
    [FastLaunchWindow setFrame:winRect display:YES animate:YES];
}

- (IBAction)showDetails {
    if ([DetailsTriangle state] == NSControlStateValueOff) {
        [DetailsTriangle performClick:DetailsTriangle];
    }
}

- (IBAction)hideDetails {
    if ([DetailsTriangle state] != NSControlStateValueOff) {
        [DetailsTriangle performClick:DetailsTriangle];
    }
}

- (BOOL)validateMenuItem:(NSMenuItem *)anItem {
    SEL selector = [anItem action];
    if (acceptsFiles && selector == @selector(openFiles:)) {
        return YES;
    }
    if ([anItem action] == @selector(savePlist2:) ||
        [anItem action] == @selector(buttonDonations:) ||
        [anItem action] == @selector(menuItemSelected:)) {
        return YES;
    }
    return NO;
}

- (IBAction)cancel:(id)sender {
    if (task && [task isRunning]) {
        PLog(@"Task cancelled");
        [task terminate];
        jobQueue = [NSMutableArray array];
    }
    if ([[sender title] isEqualToString:@"Quit"]) {
        [[NSApplication sharedApplication] terminate:self];
    }
}

- (IBAction)buttonClick:(id)sender {
    if (![task isRunning]) {
        [self executeScript1];
        [myImageView setImage:nil];
    }
}

#pragma mark - App open files

- (void)application:(NSApplication *)theApplication openFiles:(NSArray *)filenames {
    PLog(@"Received openFiles event for files: %@", [filenames description]);

    BOOL success = [self addDroppedFilesJob:filenames];
    [NSApp replyToOpenOrPrint:success ? NSApplicationDelegateReplySuccess : NSApplicationDelegateReplyFailure];

    if (success && !isTaskRunning && hasFinishedLaunching) {
        [self executeScript];
    }
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    if (task) {
        if ([task isRunning]) {
            [task terminate];
        }
        task = nil;
    }
    return NSTerminateNow;
}

#pragma mark - Interface manipulation

- (void)initialiseInterface {
    // Settings
    [self loadSettingsIfNeeded];
    self.plistFileName = [self preferencesPlistPath];

    // Binding current values ​​from settings
    _currentlySelectedPort1 = settingsCache[@"VEncoder"];
    [self.testArray1 addObject:@{ @"name" : @"H.264 (x264)" }];
    [self.testArray1 addObject:@{ @"name" : @"H.264 Hardware" }];
    [self.testArray1 addObject:@{ @"name" : @"H.265 (x265)" }];
    [self.testArray1 addObject:@{ @"name" : @"H.265 Hardware" }];

    _currentlySelectedPort2 = settingsCache[@"AEncoder"];
    [self.testArray2 addObject:@{ @"name" : @"aac" }];
    [self.testArray2 addObject:@{ @"name" : @"ac3" }];
    [self.testArray2 addObject:@{ @"name" : @"mp3" }];

    _currentlySelectedPort3 = settingsCache[@"VBitRate"];
    NSArray *bitRates = @[ @"Auto",@"Source",@"1000k",@"2000k",@"3000k",@"6000k",@"7000k",@"8000k",@"9000k",@"10000k",@"11000k",@"12000k",@"13000k",@"14000k",@"15000k",@"20000k",@"25000k",@"30000k",@"50000k",@"70000k",@"100000k" ];
    for (NSString *b in bitRates) { [self.testArray3 addObject:@{ @"name" : b }]; }

    _currentlySelectedPort4 = settingsCache[@"Resolution"];
    NSArray *resolutions = @[ @"Source",@"480x320",@"640x480",@"720x480",@"960x640",@"1280x720",@"1920x1080",@"2560x1440",@"3840x2160" ];
    for (NSString *r in resolutions) { [self.testArray4 addObject:@{ @"name" : r }]; }

    _currentlySelectedPort5 = settingsCache[@"Preset"];
    NSArray *presets = @[ @"ultrafast",@"superfast",@"veryfast",@"faster",@"fast",@"medium",@"slow",@"slower" ];
    for (NSString *p in presets) { [self.testArray5 addObject:@{ @"name" : p }]; }

    _currentlySelectedPort6 = settingsCache[@"FrameRate"];
    NSArray *fps = @[ @"Source",@"23.976",@"24",@"25",@"29.97",@"30",@"50",@"59.94",@"60" ];
    for (NSString *f in fps) { [self.testArray6 addObject:@{ @"name" : f }]; }

    _currentlySelectedPort7 = settingsCache[@"Chroma"];
    NSArray *chroma = @[ @"yuv420p",@"yuv420p10le",@"yuv422p",@"yuv422p10le",@"yuv444p",@"yuv444p10le" ];
    for (NSString *c in chroma) { [self.testArray7 addObject:@{ @"name" : c }]; }

    _currentlySelectedPort8 = settingsCache[@"ABitRate"];
    NSArray *ab = @[ @"64k",@"96k",@"112k",@"128k",@"160k",@"192k",@"224k",@"256k",@"320k",@"384k",@"448k" ];
    for (NSString *a in ab) { [self.testArray8 addObject:@{ @"name" : a }]; }

    _currentlySelectedPort9 = settingsCache[@"SampleRate"];
    NSArray *sr = @[ @"48000",@"44100",@"32000",@"22050" ];
    for (NSString *s in sr) { [self.testArray9 addObject:@{ @"name" : s }]; }

    _currentlySelectedPort10 = settingsCache[@"Mode"];
    NSArray *modes = @[ @"Encoding and Server",@"Only FTP-server",@"Only Encoding" ];
    for (NSString *m in modes) { [self.testArray10 addObject:@{ @"name" : m }]; }

    _currentlySelectedPort11 = settingsCache[@"Channels"];
    NSArray *channels = @[ @"1",@"2",@"4",@"5",@"6" ];
    for (NSString *ch in channels) { [self.testArray11 addObject:@{ @"name" : ch }]; }

    _currentlySelectedPort12 = settingsCache[@"AspectRatio"];
    NSArray *aspects = @[ @"Source",@"16:10",@"16:9",@"4:3",@"3:2",@"5:4",@"5:3" ];
    for (NSString *ar in aspects) { [self.testArray12 addObject:@{ @"name" : ar }]; }

    _InterlacedKey = settingsCache[@"Interlaced"];
    self.InterlacedKey = _InterlacedKey;

    _WaitKey = settingsCache[@"Wait"];
    self.WaitKey = _WaitKey;

    _XMLfileKey = settingsCache[@"XMLfile"];
    self.XMLfileKey = _XMLfileKey;

    _ServerKey = settingsCache[@"sr"];
    self.ServerKey = _ServerKey;

    _UserKey = settingsCache[@"un"];
    self.UserKey = _UserKey;

    _Folder1 = settingsCache[@"MonitoringFolder"];
    self.Folder1 = _Folder1;

    _Folder2 = settingsCache[@"DestinationFolder"];
    self.Folder2 = _Folder2;

    [self requestKeychainPasswordIfNeeded];

    [self PathForDeleteFile];
    [self pathForDataFile];
    [self pathForDatafolder1];
    [self pathForDatafolder2];

    // Default progress bar color
    [self applyProgressFilterForMode:@"GREY"];
    [progressBarIndicator setDoubleValue:0];

    if ([_currentlySelectedPort1 isEqual:@"H.265 (x265)"]) {
        [Interlaced setEnabled:NO];
    } else if ([_currentlySelectedPort1 isEqual:@"H.264 Hardware"]) {
        [Interlaced setEnabled:NO];
        [Preset setEnabled:NO];
    } else if ([_currentlySelectedPort1 isEqual:@"H.265 Hardware"]) {
        [Interlaced setEnabled:NO];
        [Preset setEnabled:NO];
    }

    [openRecentMenuItem setEnabled:acceptsFiles];
    if (!acceptsFiles) {
        [fileMenu removeItemAtIndex:0];
        [fileMenu removeItemAtIndex:0];
        [fileMenu removeItemAtIndex:0];
    }

    if (runInBackground) {
        [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    }

    if (isDroppable) {
        [FastLaunchWindow registerForDraggedTypes:@[NSPasteboardTypeFileURL, NSPasteboardTypeString]];
    }

    if ([DEFAULTS boolForKey:@"UserShowDetails"]) {
        NSRect frame = [FastLaunchWindow frame];
        frame.origin.y += detailsHeight;
        [FastLaunchWindow setFrame:frame display:NO];
        [self showDetails];
    }

    [FastLaunchWindow makeKeyAndOrderFront:self];
}

- (void)requestKeychainPasswordIfNeeded {
    // Read from Keychain only once at startup
    if (self.PassKey.length > 0) { return; }
    NSTask *taskPass = [[NSTask alloc] init];
    [taskPass setLaunchPath:@"/bin/bash"];
    [taskPass setArguments:[NSArray arrayWithObjects: @"-c", @"/usr/bin/security find-generic-password -a ${USER} -s postftp -w | tr -d '\n' 2>/dev/null", nil]];
    NSPipe *Pipe;
    Pipe = [NSPipe pipe];
    [taskPass setStandardOutput: Pipe];
    [taskPass setStandardInput:[NSPipe pipe]];
    NSFileHandle *file;
    file = [Pipe fileHandleForReading];
    [taskPass launch];
    NSData *data;
    data = [file readDataToEndOfFile];
    _PassKey = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    //  NSLog(@"%@",_PassKey);
    self.PassKey = _PassKey;
}

- (void)prepareInterfaceForExecution {
    dispatch_async(dispatch_get_main_queue(), ^{
        [outputTextView setString:@"\u200B"];
        [CancelButton setTitle:@"Cancel"];
        [self setControlsEnabled:NO];
        [[DockProgressBarRed sharedDockProgressBarRed] clearRed];
        [myImageView setImage:nil];
        self.FileString = nil;
        self.SecondsString = nil;
        self.OnlyString = nil;
        [self applyProgressFilterForMode:@"GREY"];
        [progressBarIndicator setDoubleValue:0];
    });
}

- (void)cleanupInterface {
    dispatch_async(dispatch_get_main_queue(), ^{
        [CancelButton setTitle:@"Quit"];
        [self setControlsEnabled:YES];
    });
}

#pragma mark - Task

- (void)prepareForExecution {
    [arguments removeAllObjects];
    [arguments addObjectsFromArray:(interpreterArgs ? interpreterArgs : @[])];

    if (![FILEMGR fileExistsAtPath:scriptDropPath]) {
        NSLog(@"Script missing at execution path %@", scriptDropPath);
    }
    [arguments addObject:scriptDropPath];

    if (jobQueue.count > 0) {
        FastLaunchJob *job = jobQueue.firstObject;
        if (job.arguments) {
            [arguments addObjectsFromArray:job.arguments];
        }
        stdinString = [job.standardInputString copy];
        [jobQueue removeObjectAtIndex:0];
    }
}

- (void)prepareForExecution1 {
    [arguments removeAllObjects];
    [arguments addObjectsFromArray:(interpreterArgs ? interpreterArgs : @[])];

    if (![FILEMGR fileExistsAtPath:scriptStartPath]) {
        NSLog(@"Script missing at execution path %@", scriptStartPath);
    }
    [arguments addObject:scriptStartPath];
}

- (void)executeScript {
    hasTaskRun = YES;
    if (isTaskRunning) { return; }
    outputEmpty = NO;

    [self prepareForExecution];
    [self prepareInterfaceForExecution];

    isTaskRunning = YES;
    [self executeScriptWithoutPrivileges];
}

- (void)executeScript1 {
    hasTaskRun = YES;
    if (isTaskRunning) { return; }
    outputEmpty = NO;

    [self prepareForExecution1];
    [self prepareInterfaceForExecution];

    isTaskRunning = YES;
    [self executeScriptWithoutPrivileges];
}

- (void)executeScriptWithoutPrivileges {
    task = [[NSTask alloc] init];
    [task setLaunchPath:interpreterPath];
    [task setCurrentDirectoryPath:[[NSBundle mainBundle] resourcePath]];
    [task setArguments:arguments];

    outputPipe = [NSPipe pipe];
    [task setStandardOutput:outputPipe];
    [task setStandardError:outputPipe];
    outputReadFileHandle = [outputPipe fileHandleForReading];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gotOutputData:) name:NSFileHandleReadCompletionNotification object:outputReadFileHandle];
    [outputReadFileHandle readInBackgroundAndNotify];

    inputPipe = [NSPipe pipe];
    [task setStandardInput:inputPipe];
    inputWriteFileHandle = [[task standardInput] fileHandleForWriting];

    [task launch];

    if (stdinString) {
        [inputWriteFileHandle writeData:[stdinString dataUsingEncoding:NSUTF8StringEncoding]];
    }
    [inputWriteFileHandle closeFile];
    stdinString = nil;
}

#pragma mark - Task completion

- (void)taskFinished:(NSNotification *)aNotification {
    isTaskRunning = NO;
    PLog(@"Task finished");

    if (outputEmpty) {
        [self cleanup];
    }
    if (jobQueue.count > 0) {
        [self executeScript];
    }
}

- (void)cleanup {
    if (isTaskRunning) { return; }

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSFileHandleReadCompletionNotification
                                                  object:outputReadFileHandle];

    if (outputReadFileHandle) {
        NSData *data;
        while ((data = [outputReadFileHandle availableData]) && data.length) {
            [self parseOutput:data];
        }
        [outputReadFileHandle closeFile];
        outputReadFileHandle = nil;
    }

    [self cleanupInterface];
    isService = YES;
}

#pragma mark - Output parsing

- (void)gotOutputData:(NSNotification *)aNotification {
    NSData *data = aNotification.userInfo[NSFileHandleNotificationDataItem];

    if (data.length) {
        outputEmpty = NO;
        [self parseOutput:data];
        [[aNotification object] readInBackgroundAndNotify];
    } else {
        PLog(@"Output empty");
        outputEmpty = YES;
        if (!isTaskRunning) {
            [self cleanup];
        }
        if (!remainRunning) {
            [[NSApplication sharedApplication] terminate:self];
        }
    }
}

- (NSString *)cleanedLine:(NSString *)line {
    if (!line) return @"";
    NSString *trimmed = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    // Remove leading control characters
    while (trimmed.length > 0) {
        unichar c = [trimmed characterAtIndex:0];
        if ([[NSCharacterSet controlCharacterSet] characterIsMember:c]) {
            trimmed = [trimmed substringFromIndex:1];
        } else {
            break;
        }
    }
    return trimmed;
}

- (void)handleParsedLine:(NSString *)theLine {
    NSString *line = [self cleanedLine:theLine];
    if (line.length == 0) { return; }

    // NOTIFICATION:
    NSRange notifRange = [line rangeOfString:@"NOTIFICATION:"];
    if (notifRange.location != NSNotFound) {
        NSString *notificationString = @"";
        NSUInteger start = notifRange.location + notifRange.length;
        if (start < line.length) {
            notificationString = [[theLine substringFromIndex:start] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        }
        [self showNotification:notificationString];
        return;
    }

    if ([line hasPrefix:@"Name:"]) {
        NSString *NameString = [[theLine substringFromIndex:5] stringByTrimmingCharactersInSet:NSCharacterSet.newlineCharacterSet];
        dispatch_async(dispatch_get_main_queue(), ^{
            [MessageTextFieldName setStringValue:NameString];
        });
        return;
    }

    if ([line hasPrefix:@"ONLY:"]) {
        self.OnlyString = [[theLine substringFromIndex:5] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
        return;
    }

    if ([line hasPrefix:@"Progress:"]) {
        NSString *ProgressString = [[theLine substringFromIndex:9] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
        dispatch_async(dispatch_get_main_queue(), ^{
            [MessageTextFieldProgress setStringValue:ProgressString];
        });
        self.ProgressString = ProgressString;
        return;
    }

    if ([line hasPrefix:@"FPS:"]) {
        NSString *FPSString = [[theLine substringFromIndex:4] stringByTrimmingCharactersInSet:NSCharacterSet.newlineCharacterSet];
        dispatch_async(dispatch_get_main_queue(), ^{
            [MessageTextFieldFPS setStringValue:FPSString];
        });
        return;
    }

    if ([line hasPrefix:@"Size:"]) {
        NSString *SizeString = [[theLine substringFromIndex:5] stringByTrimmingCharactersInSet:NSCharacterSet.newlineCharacterSet];
        dispatch_async(dispatch_get_main_queue(), ^{
            [MessageTextFieldSize setStringValue:SizeString];
        });
        return;
    }

    if ([line hasPrefix:@"Duration:"]) {
        NSString *DurationString = [[theLine substringFromIndex:9] stringByTrimmingCharactersInSet:NSCharacterSet.newlineCharacterSet];
        dispatch_async(dispatch_get_main_queue(), ^{
            [MessageTextFieldDuration setStringValue:DurationString];
        });
        return;
    }

    if ([line hasPrefix:@"Time:"]) {
        NSString *TimeString = [[theLine substringFromIndex:5] stringByTrimmingCharactersInSet:NSCharacterSet.newlineCharacterSet];
        dispatch_async(dispatch_get_main_queue(), ^{
            [MessageTextFieldTime setStringValue:TimeString];
        });
        return;
    }

    if ([line hasPrefix:@"Speed:"]) {
        NSString *SpeedString = [[theLine substringFromIndex:6] stringByTrimmingCharactersInSet:NSCharacterSet.newlineCharacterSet];
        dispatch_async(dispatch_get_main_queue(), ^{
            [MessageTextFieldSpeed setStringValue:SpeedString];
        });
        return;
    }

    if ([line hasPrefix:@"Media:"]) {
        NSString *MediaString = [[theLine substringFromIndex:6] stringByTrimmingCharactersInSet:NSCharacterSet.newlineCharacterSet];
        dispatch_async(dispatch_get_main_queue(), ^{
            [MessageTextFieldMediaInfo setStringValue:MediaString];
        });
        return;
    }

    if ([line hasPrefix:@"Files:"]) {
        self.FileString = [[theLine substringFromIndex:6] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
        return;
    }

    if ([line hasPrefix:@"Seconds:"]) {
        self.SecondsString = [[theLine substringFromIndex:8] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
        return;
    }

    if ([line hasPrefix:@"Info:"]) {
        NSString *InfoString = [[theLine substringFromIndex:5] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
        dispatch_async(dispatch_get_main_queue(), ^{
            [MessageTextFieldInfo setStringValue:InfoString];
        });
        return;
    }
}

- (void)parseOutput:(NSData *)data {
    NSMutableString *outputString = [[NSMutableString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (!outputString) {
        PLog(@"Warning: Output string is nil");
        return;
    }

    if (remnants) {
        [outputString insertString:remnants atIndex:0];
    }

    // Separation
    NSMutableArray<NSString *> *lines = [[outputString componentsSeparatedByString:@"\n"] mutableCopy];

    if (lines.lastObject.length > 0) {
        remnants = lines.lastObject;
    } else {
        remnants = nil;
    }
    [lines removeLastObject];

    // Business logic on diffs (picture/progress)
    if (self.FileString.length > 0 && ![self.SecondsString isEqualToString:self.SecondsStringOld]) {
        [self videoSlides];
    }
    self.SecondsStringOld = self.SecondsString;

    if (self.ProgressString.length > 0 && ![self.ProgressString isEqualToString:self.ProgressStringOld]) {
        [self progressBarProgram];
    }
    self.ProgressStringOld = self.ProgressString;

    for (NSString *theLine in lines) {
        [self handleParsedLine:theLine];
    }
}

#pragma mark - Video thumbnail

- (void)videoSlides {
    if (self.FileString.length == 0) { return; }

    NSString *urlString = [self.FileString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];
    NSURL *videoURL = [NSURL URLWithString:urlString];
    if (!videoURL) { return; }

    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoURL options:nil];
    if (!asset) {
        NSLog(@"AVURLAsset init failed for URL: %@", self.FileString);
        return;
    }

    AVAssetImageGenerator *imgGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    imgGenerator.appliesPreferredTrackTransform = YES;
    imgGenerator.maximumSize = CGSizeMake(260, 146);
    imgGenerator.apertureMode = AVAssetImageGeneratorApertureModeProductionAperture;
 // imgGenerator.requestedTimeToleranceBefore = kCMTimeZero;
 // imgGenerator.requestedTimeToleranceAfter = kCMTimeZero;
    
    CMTimeScale ts = (asset.duration.timescale ? asset.duration.timescale : 600);
    Float64 seconds = [self.SecondsString doubleValue];
    CMTime time = CMTimeMakeWithSeconds(seconds, ts);

    NSError *error = nil;
    CGImageRef imageRef = [imgGenerator copyCGImageAtTime:time actualTime:NULL error:&error];

    void (^applyImageOnMain)(NSImage *) = ^(NSImage *image){
        dispatch_async(dispatch_get_main_queue(), ^{
            if (image) {
                [myImageView setImage:image];
            } else if (isService) {
                NSImage *thumbnail = [[NSImage alloc] initWithContentsOfFile:@"/private/tmp/img.png"];
                [myImageView setImage:thumbnail];
            }
        });
    };

    if (!imageRef) {
        if (error) {
           // PLog(@"AVAssetImageGenerator failed: %@", error.localizedDescription);
        }
        applyImageOnMain(nil);
        return;
    }

    NSImage *thumbnail = [[NSImage alloc] initWithCGImage:imageRef size:NSMakeSize(260, 146)];
    CGImageRelease(imageRef);
    isService = NO;
    applyImageOnMain(thumbnail);
}

#pragma mark - Progress

- (void)progressBarProgram {
    NSString *mode = (self.OnlyString ? self.OnlyString : @"GREY");
    double value = self.ProgressString.doubleValue;

    if ([mode isEqualToString:@"RED"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [CancelButton setTitle:@"Cancel"];
            [[DockProgressBarBlue sharedDockProgressBarBlue] hideProgressBarBlue];
        });
        double progressRed = value / 100.0;
        [[DockProgressBarRed sharedDockProgressBarRed] setProgressRed:(float)progressRed];
        [[DockProgressBarRed sharedDockProgressBarRed] updateProgressBarRed];
        [self updateProgressBarWithPercent:value mode:@"RED"];
    } else if ([mode isEqualToString:@"BLUE"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [CancelButton setTitle:@"Pause"];
            [[DockProgressBarRed sharedDockProgressBarRed] hideProgressBarRed];
        });
        double progressBlue = value / 100.0;
        [[DockProgressBarBlue sharedDockProgressBarBlue] setProgressBlue:(float)progressBlue];
        [[DockProgressBarBlue sharedDockProgressBarBlue] updateProgressBarBlue];
        [self updateProgressBarWithPercent:value mode:@"BLUE"];
    } else { // GREY
        [self applyProgressFilterForMode:@"GREY"];
        dispatch_async(dispatch_get_main_queue(), ^{
            [progressBarIndicator setDoubleValue:0];
        });
    }

    if ([self.ProgressString isEqualToString:@"0% "]) {
        [[DockProgressBarRed sharedDockProgressBarRed] clearRed];
    }
}

#pragma mark - Service handling

- (void)dropService:(NSPasteboard *)pb userData:(NSString *)userData error:(NSString **)err {
    PLog(@"Received drop service data");
    BOOL ret = 0;

    if (acceptsFiles && [[pb types] containsObject:NSPasteboardTypeFileURL]) {
        NSArray<NSString *> *paths = [self safePathsFromPasteboard:pb];
        ret = [self addDroppedFilesJob:paths];
    } else {
        if (err) *err = @"Data type in pasteboard cannot be handled by this application.";
        return;
    }

    if (!isTaskRunning && ret) {
        [self executeScript];
    }
}

#pragma mark - Add job to queue

- (BOOL)addDroppedFilesJob:(NSArray <NSString *> *)files {
    if (!acceptsFiles) { return NO; }
    if (files.count == 0) { return NO; }

    NSMutableArray *acceptedFiles = [NSMutableArray array];
    for (NSString *file in files) {
        BOOL isDir = NO;
        BOOL exists = [FILEMGR fileExistsAtPath:file isDirectory:&isDir];
        if (!exists) { continue; }
        if (isDir && !acceptDroppedFolders) { continue; }
        if (acceptAnyDroppedItem || !isDir) {
            [acceptedFiles addObject:file];
        }
    }
    if (acceptedFiles.count == 0) { return NO; }

    FastLaunchJob *job = [FastLaunchJob jobWithArguments:acceptedFiles andStandardInput:nil];
    [jobQueue addObject:job];

    for (NSString *path in acceptedFiles) {
        [[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:[NSURL fileURLWithPath:path]];
    }
    return YES;
}

- (BOOL)addMenuItemSelectedJob:(NSString *)menuItemTitle {
    FastLaunchJob *job = [FastLaunchJob jobWithArguments:@[menuItemTitle] andStandardInput:nil];
    [jobQueue addObject:job];
    return YES;
}

#pragma mark - Drag and drop handling

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    if ([sender draggingSource]) {
        return NSDragOperationNone;
    }

    BOOL acceptDrag = NO;
    NSPasteboard *pboard = [sender draggingPasteboard];

    if ([[pboard types] containsObject:NSPasteboardTypeString] && acceptsText) {
        acceptDrag = YES;
    } else if ([[pboard types] containsObject:NSPasteboardTypeFileURL] && acceptsFiles) {
        NSArray<NSURL*> *files = [pboard readObjectsForClasses:@[[NSURL class]] options:@{}];
        for (NSURL *url in files) {
            NSString *file = url.path;
            BOOL isDir = NO;
            BOOL exists = [FILEMGR fileExistsAtPath:file isDirectory:&isDir];
            if (exists && (!isDir || acceptDroppedFolders)) {
                acceptDrag = YES;
                break;
            }
        }
    }

    return acceptDrag ? NSDragOperationLink : NSDragOperationNone;
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender { return YES; }

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard = [sender draggingPasteboard];
    if ([[pboard types] containsObject:NSPasteboardTypeFileURL]) {
        NSArray<NSString *> *paths = [self safePathsFromPasteboard:pboard];
        if (paths.count > 0) {
            return [self addDroppedFilesJob:paths];
        }
        return NO;
    }
    return NO;
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender {
    if (!isTaskRunning && jobQueue.count > 0) {
        [NSTimer scheduledTimerWithTimeInterval:0.0f target:self selector:@selector(executeScript) userInfo:nil repeats:NO];
    }
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender {
    return [self draggingEntered:sender];
}

- (IBAction)menuItemSelected:(id)sender {
    [self addMenuItemSelectedJob:[sender title]];
    if (!isTaskRunning && jobQueue.count > 0) {
        [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(executeScript) userInfo:nil repeats:NO];
    }
}

#pragma mark - Utility methods

- (void)showNotification:(NSString *)notificationText {
    if (notificationText.length == 0) { return; }

    // If the user has disabled notifications in the app settings (your flag), do nothing.
    if (!sendsNotifications) { return; }

    if (@available(macOS 11.0, *)) {
        UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
        content.body = notificationText;
        content.sound = [UNNotificationSound defaultSound];

        UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:0.1 repeats:NO];
        NSString *identifier = [[NSUUID UUID] UUIDString];
        UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier content:content trigger:trigger];

        [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
            if (error) {
                NSLog(@"Failed to deliver notification: %@", error.localizedDescription);
            }
        }];
    } else {
        // macOS 10.15 and below: Use legacy NSUserNotificationCenter to show a notification when an app is active.
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title = [[NSProcessInfo processInfo] processName];
        notification.informativeText = notificationText;
        notification.soundName = NSUserNotificationDefaultSoundName;

        NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
        center.delegate = (id<NSUserNotificationCenterDelegate>)self;
        [center deliverNotification:notification];
    }
}

// Delegate for legacy NSUserNotificationCenter (macOS 10.15): Show even when app is active
- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification {
    return YES;
}

- (IBAction)buttonDonations:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=2BREZMHRLQNZ4&source=url"]];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication { return YES; }

#pragma mark - Safe helpers

- (NSArray<NSString *> *)safePathsFromOpenPanelURLs:(NSArray<NSURL *> *)urls {
    NSMutableArray<NSString *> *paths = [NSMutableArray arrayWithCapacity:urls.count];
    for (NSURL *url in urls) {
        if (url.isFileURL) {
            [paths addObject:url.path];
        }
    }
    return paths;
}

- (NSArray<NSString *> *)safePathsFromPasteboard:(NSPasteboard *)pboard {
    NSArray<NSURL *> *urls = [pboard readObjectsForClasses:@[[NSURL class]]
                                                   options:@{ NSPasteboardURLReadingFileURLsOnlyKey : @YES }];
    NSMutableArray<NSString *> *paths = [NSMutableArray arrayWithCapacity:urls.count];
    for (NSURL *u in urls) {
        if (u.isFileURL) {
            [paths addObject:u.path];
        }
    }
    return paths;
}

@end

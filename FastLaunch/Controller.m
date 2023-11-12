

#import "Controller.h"
#import "FastLaunchJob.h"
#import "DockProgressBarRed.h"
#import "DockProgressBarBlue.h"
#import <Quartz/Quartz.h>

// Abbreviations. Objective-C is often tediously verbose
#define FILEMGR     [NSFileManager defaultManager]
#define DEFAULTS    [NSUserDefaults standardUserDefaults]

// Logging
#ifdef DEBUG
    #define PLog(...) NSLog(__VA_ARGS__)
#else
    #define PLog(...)
#endif

#ifdef DEBUG
#endif

@import AVFoundation;

@interface Controller()
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
    NSArray <NSString *> *commandLineArguments;
    NSArray <NSString *> *interpreterArgs;
    NSArray <NSString *> *scriptArgs;
    NSArray <NSString *> *script1Args;
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
@property (retain) IBOutlet NSTextField *PassTextField;
@property (retain) NSString *SecondsString;
@property (retain) NSString *SecondsStringOld;
@property (retain) NSString *ProgressString;
@property (retain) NSString *FileString;
@property (retain) NSString *OnlyString;
@property (assign) IBOutlet NSView *view;
@end

static const NSInteger detailsHeight = 310;

@implementation Controller

- (instancetype)init {
    self = [super init];
    if (self) {
        arguments = [NSMutableArray array];
        outputEmpty = YES;
        jobQueue = [NSMutableArray array];
    }
    return self;
}

- (void)awakeFromNib {
    // Load settings from app bundle
    [self loadAppSettings];
    
    // Prepare UI
    [self initialiseInterface];
    
    // Listen for terminate notification
    NSString *notificationName = NSTaskDidTerminateNotification;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(taskFinished:)
                                                 name:notificationName
                                               object:nil];
    
    // Register as text handling service
    if (isService) {
        [NSApp setServicesProvider:self];
        NSMutableArray *sendTypes = [NSMutableArray array];
        if (acceptsFiles) {
            [sendTypes addObject:NSFilenamesPboardType];
        }
        [NSApp registerServicesMenuSendTypes:sendTypes returnTypes:@[]];
    }
    
    // User Notification Center
    if (sendsNotifications) {
        [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
    }
}

#pragma mark - App Settings

- (void)loadAppSettings {
    // Application bundle
    NSBundle *bundle = [NSBundle mainBundle];
    
    // Check if /scripts/scriptDrop file exists
    scriptDropPath = [bundle pathForResource:@"/scripts/scriptDrop" ofType:nil];
    if ([FILEMGR fileExistsAtPath:scriptDropPath] == NO) {
        NSLog(@"/scripts/scriptDrop missing from application bundle.");
    }
    
    // Check if /scripts/scriptStart file exists
    scriptStartPath = [bundle pathForResource:@"/scripts/scriptStart" ofType:nil];
    if ([FILEMGR fileExistsAtPath:scriptStartPath] == NO) {
        NSLog(@"/scripts/scriptStart missing from application bundle.");
    }

    // Make sure scripts is executable and readable
    NSNumber *permissions = [NSNumber numberWithUnsignedLong:493];
    NSDictionary *attributes = @{ NSFilePosixPermissions:permissions };
    [FILEMGR setAttributes:attributes ofItemAtPath:scriptDropPath error:nil];
    if ([FILEMGR isReadableFileAtPath:scriptDropPath] == NO || [FILEMGR isExecutableFileAtPath:scriptDropPath] == NO) {
        NSLog(@"scriptDrop file is not readable/executable.");
    }
    [FILEMGR setAttributes:attributes ofItemAtPath:scriptStartPath error:nil];
    if ([FILEMGR isReadableFileAtPath:scriptStartPath] == NO || [FILEMGR isExecutableFileAtPath:scriptStartPath] == NO) {
        NSLog(@"scriptStart file is not readable/executable.");
    }

    interpreterPath = @"/bin/sh";
    remainRunning = YES;
    isDroppable = NO;
    promptForFileOnLaunch = NO;

    //  for drop
    acceptsFiles = YES;
    if (acceptsFiles) {
        acceptAnyDroppedItem = YES;
        isDroppable = TRUE;
//   acceptDroppedFolders = YES;
    }
}



- (NSString *) PathForDeleteFile
{
NSError *error;
    NSString *path = @"/private/tmp/img.jpeg";
    if ([[NSFileManager defaultManager] isDeletableFileAtPath:path]) {
    BOOL success = [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
    if (!success) {
        NSLog(@"%@", error.localizedDescription);
    }
 }
    return @"/private/tmp/img.jpeg";
}





// Create a folder and delete the contents of the folder
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
     return @"/private/tmp/FastLaunch/";
}

- (NSString *) pathForDatafolderDefault1
{
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSMoviesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
           NSString *dataPath = [path stringByAppendingPathComponent:@"/FastLaunch output"];
           NSError *error = nil;
    if (![[NSFileManager defaultManager] fileExistsAtPath:dataPath]){
        [[NSFileManager defaultManager] createDirectoryAtPath:dataPath withIntermediateDirectories:NO attributes:nil error:&error]; //Create folder
    }

    return dataPath;
}

- (NSString *) pathForDatafolderDefault2
{
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES) objectAtIndex:0];
           NSString *dataPath = [path stringByAppendingPathComponent:@"/FastLaunch input"];
           NSError *error = nil;
    if (![[NSFileManager defaultManager] fileExistsAtPath:dataPath]){
        [[NSFileManager defaultManager] createDirectoryAtPath:dataPath withIntermediateDirectories:NO attributes:nil error:&error]; //Create folder
    }

    return dataPath;
}

- (NSString *) pathForDatafolder1
{
    BOOL isDir;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *folder = self.Folder1;
    folder = [folder stringByExpandingTildeInPath];
    if(![fileManager fileExistsAtPath:folder isDirectory:&isDir]) {
        if(![fileManager createDirectoryAtPath:folder withIntermediateDirectories:YES attributes:nil error:NULL])
            NSLog(@"Error: Create folder failed %@",folder);
    }
     return folder;
}

- (NSString *) pathForDatafolder2
{
    BOOL isDir;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *folder = self.Folder2;
    folder = [folder stringByExpandingTildeInPath];
    if(![fileManager fileExistsAtPath:folder isDirectory:&isDir]) {
        if(![fileManager createDirectoryAtPath:folder withIntermediateDirectories:YES attributes:nil error:NULL])
            NSLog(@"Error: Create folder failed %@",folder);
    }
     return folder;
}


#pragma mark - App Delegate handlers


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *plistPath = [rootPath stringByAppendingPathComponent:@"/Preferences/org.SerhiiHalan.SettingsFastLaunch.plist"];
    self.plistFileName = plistPath;
    NSLog(@"plist file path: %@", plistPath);
    
    //If there is no plist, a default one is created
    NSData *plistTest = [NSData dataWithContentsOfFile:self.plistFileName];
    if (!plistTest)
    {
        NSMutableDictionary *root = [NSMutableDictionary dictionary];
        [root setObject:@"H.264" forKey:@"VEncoder"];
        [root setObject:@"aac" forKey:@"AEncoder"];
        [root setObject:@"15000k" forKey:@"VBitRate"];
        [root setObject:@"1920x1080" forKey:@"Resolution"];
        [root setObject:@"medium" forKey:@"Preset"];
        [root setObject:@"25" forKey:@"FrameRate"];
        [root setObject:@"16:9" forKey:@"AspectRatio"];
        [root setObject:@"yuv420p" forKey:@"Chroma"];
        [root setObject:@"192k" forKey:@"ABitRate"];
        [root setObject:@"Encoding and Server" forKey:@"Mode"];
        [root setObject:@"2" forKey:@"Channels"];
        [root setObject:@"48000" forKey:@"SampleRate"];
        [root setObject:@NO forKey:@"Interlaced"];
        [root setObject:@NO forKey:@"Wait"];
        [root setObject:@NO forKey:@"XMLfile"];
        [root setObject:@"" forKey:@"sr"];
        [root setObject:@"" forKey:@"un"];
        [root setObject:self.pathForDatafolderDefault1 forKey:@"DestinationFolder"];
        [root setObject:self.pathForDatafolderDefault2 forKey:@"MonitoringFolder"];
        NSLog(@"Default settings saving data:\n%@", root);
        NSError *error = nil;
        NSData *representation = [NSPropertyListSerialization dataWithPropertyList:root format:NSPropertyListBinaryFormat_v1_0 options:0 error:&error];
        [representation writeToFile:self.plistFileName atomically:YES];
        [self pathForDatafolderDefault1];
        [self pathForDatafolderDefault2];
    }
    
    //Get the keys from the plist
    NSData *plistData = [NSData dataWithContentsOfFile:self.plistFileName];
    if (!plistData)
    {
        NSLog(@"error reading from file: %@", self.plistFileName);
    }
    NSPropertyListFormat format;
    NSError *error = nil;
    id plist = [NSPropertyListSerialization propertyListWithData:plistData options:NSPropertyListMutableContainersAndLeaves format:&format error:&error];
    if (!error)
    {
        NSMutableDictionary *root = plist;
        NSLog(@"loaded data:\n%@", root);
    }
    else
    {
        NSLog(@"error: %@", error);
    }
    
    _currentlySelectedPort1 = ((void)(@"%@"), [plist objectForKey:@"VEncoder"]);
    [self.testArray1 addObject:@{ @"name" : @"H.264" }];
    [self.testArray1 addObject:@{ @"name" : @"H.265" }];
    
    _currentlySelectedPort2 = ((void)(@"%@"), [plist objectForKey:@"AEncoder"]);
    [self.testArray2 addObject:@{ @"name" : @"aac" }];
    [self.testArray2 addObject:@{ @"name" : @"ac3" }];
    [self.testArray2 addObject:@{ @"name" : @"mp3" }];
    
    _currentlySelectedPort3 = ((void)(@"%@"), [plist objectForKey:@"VBitRate"]);
    [self.testArray3 addObject:@{ @"name" : @"Auto" }];
    [self.testArray3 addObject:@{ @"name" : @"Source" }];
    [self.testArray3 addObject:@{ @"name" : @"1000k" }];
    [self.testArray3 addObject:@{ @"name" : @"2000k" }];
    [self.testArray3 addObject:@{ @"name" : @"3000k" }];
    [self.testArray3 addObject:@{ @"name" : @"6000k" }];
    [self.testArray3 addObject:@{ @"name" : @"7000k" }];
    [self.testArray3 addObject:@{ @"name" : @"8000k" }];
    [self.testArray3 addObject:@{ @"name" : @"9000k" }];
    [self.testArray3 addObject:@{ @"name" : @"10000k" }];
    [self.testArray3 addObject:@{ @"name" : @"11000k" }];
    [self.testArray3 addObject:@{ @"name" : @"12000k" }];
    [self.testArray3 addObject:@{ @"name" : @"13000k" }];
    [self.testArray3 addObject:@{ @"name" : @"14000k" }];
    [self.testArray3 addObject:@{ @"name" : @"15000k" }];
    [self.testArray3 addObject:@{ @"name" : @"20000k" }];
    [self.testArray3 addObject:@{ @"name" : @"25000k" }];
    [self.testArray3 addObject:@{ @"name" : @"30000k" }];
    [self.testArray3 addObject:@{ @"name" : @"50000k" }];
    
    _currentlySelectedPort4 = ((void)(@"%@"), [plist objectForKey:@"Resolution"]);
    [self.testArray4 addObject:@{ @"name" : @"Source" }];
    [self.testArray4 addObject:@{ @"name" : @"480x320" }];
    [self.testArray4 addObject:@{ @"name" : @"640x480" }];
    [self.testArray4 addObject:@{ @"name" : @"720x480" }];
    [self.testArray4 addObject:@{ @"name" : @"960x640" }];
    [self.testArray4 addObject:@{ @"name" : @"1280x720" }];
    [self.testArray4 addObject:@{ @"name" : @"1920x1080" }];
    [self.testArray4 addObject:@{ @"name" : @"2560x1440" }];
    [self.testArray4 addObject:@{ @"name" : @"3840x2160" }];
    
    _currentlySelectedPort5 = ((void)(@"%@"), [plist objectForKey:@"Preset"]);
    [self.testArray5 addObject:@{ @"name" : @"ultrafast" }];
    [self.testArray5 addObject:@{ @"name" : @"superfast" }];
    [self.testArray5 addObject:@{ @"name" : @"veryfast" }];
    [self.testArray5 addObject:@{ @"name" : @"faster" }];
    [self.testArray5 addObject:@{ @"name" : @"fast" }];
    [self.testArray5 addObject:@{ @"name" : @"medium" }];
    [self.testArray5 addObject:@{ @"name" : @"slow" }];
    [self.testArray5 addObject:@{ @"name" : @"slower" }];
    
    _currentlySelectedPort6 = ((void)(@"%@"), [plist objectForKey:@"FrameRate"]);
    [self.testArray6 addObject:@{ @"name" : @"Source" }];
    [self.testArray6 addObject:@{ @"name" : @"23.976" }];
    [self.testArray6 addObject:@{ @"name" : @"24" }];
    [self.testArray6 addObject:@{ @"name" : @"25" }];
    [self.testArray6 addObject:@{ @"name" : @"29.97" }];
    [self.testArray6 addObject:@{ @"name" : @"30" }];
    [self.testArray6 addObject:@{ @"name" : @"50" }];
    [self.testArray6 addObject:@{ @"name" : @"59.94" }];
    [self.testArray6 addObject:@{ @"name" : @"60" }];
    
    _currentlySelectedPort7 = ((void)(@"%@"), [plist objectForKey:@"Chroma"]);
    [self.testArray7 addObject:@{ @"name" : @"yuv420p" }];
    [self.testArray7 addObject:@{ @"name" : @"yuv420p10le" }];
    [self.testArray7 addObject:@{ @"name" : @"yuv422p" }];
    [self.testArray7 addObject:@{ @"name" : @"yuv422p10le" }];
    [self.testArray7 addObject:@{ @"name" : @"yuv444p" }];
    [self.testArray7 addObject:@{ @"name" : @"yuv444p10le" }];
    
    _currentlySelectedPort8 = ((void)(@"%@"), [plist objectForKey:@"ABitRate"]);
    [self.testArray8 addObject:@{ @"name" : @"64k" }];
    [self.testArray8 addObject:@{ @"name" : @"96k" }];
    [self.testArray8 addObject:@{ @"name" : @"112k" }];
    [self.testArray8 addObject:@{ @"name" : @"128k" }];
    [self.testArray8 addObject:@{ @"name" : @"160k" }];
    [self.testArray8 addObject:@{ @"name" : @"192k" }];
    [self.testArray8 addObject:@{ @"name" : @"224k" }];
    [self.testArray8 addObject:@{ @"name" : @"256k" }];
    [self.testArray8 addObject:@{ @"name" : @"320k" }];
    [self.testArray8 addObject:@{ @"name" : @"384k" }];
    [self.testArray8 addObject:@{ @"name" : @"448k" }];
    
    _currentlySelectedPort9 = ((void)(@"%@"), [plist objectForKey:@"SampleRate"]);
    [self.testArray9 addObject:@{ @"name" : @"48000" }];
    [self.testArray9 addObject:@{ @"name" : @"44100" }];
    [self.testArray9 addObject:@{ @"name" : @"32000" }];
    [self.testArray9 addObject:@{ @"name" : @"22050" }];
    
    _currentlySelectedPort10 = ((void)(@"%@"), [plist objectForKey:@"Mode"]);
    [self.testArray10 addObject:@{ @"name" : @"Encoding and Server" }];
    [self.testArray10 addObject:@{ @"name" : @"Only FTP-server" }];
    [self.testArray10 addObject:@{ @"name" : @"Only Encoding" }];
    
    _currentlySelectedPort11 = ((void)(@"%@"), [plist objectForKey:@"Channels"]);
    [self.testArray11 addObject:@{ @"name" : @"1" }];
    [self.testArray11 addObject:@{ @"name" : @"2" }];
    [self.testArray11 addObject:@{ @"name" : @"4" }];
    [self.testArray11 addObject:@{ @"name" : @"5" }];
    [self.testArray11 addObject:@{ @"name" : @"6" }];
    
    _currentlySelectedPort12 = ((void)(@"%@"), [plist objectForKey:@"AspectRatio"]);
    [self.testArray12 addObject:@{ @"name" : @"Source" }];
    [self.testArray12 addObject:@{ @"name" : @"16:10" }];
    [self.testArray12 addObject:@{ @"name" : @"16:9" }];
    [self.testArray12 addObject:@{ @"name" : @"4:3" }];
    [self.testArray12 addObject:@{ @"name" : @"3:2" }];
    [self.testArray12 addObject:@{ @"name" : @"5:4" }];
    [self.testArray12 addObject:@{ @"name" : @"5:3" }];
    
    _InterlacedKey = ((void)(@"%@"), [plist objectForKey:@"Interlaced"]);
    self.InterlacedKey = _InterlacedKey;
    
    _WaitKey = ((void)(@"%@"), [plist objectForKey:@"Wait"]);
    self.WaitKey = _WaitKey;
    
    _XMLfileKey = ((void)(@"%@"), [plist objectForKey:@"XMLfile"]);
    self.XMLfileKey = _XMLfileKey;
    
    _ServerKey = ((void)(@"%@"), [plist objectForKey:@"sr"]);
    self.ServerKey = _ServerKey;
    
    _UserKey = ((void)(@"%@"), [plist objectForKey:@"un"]);
    self.UserKey = _UserKey;
    
    _Folder1 = ((void)(@"%@"), [plist objectForKey:@"MonitoringFolder"]);
    self.Folder1 = _Folder1;
    
    _Folder2 = ((void)(@"%@"), [plist objectForKey:@"DestinationFolder"]);
    self.Folder2 = _Folder2;
    
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
    [self PathForDeleteFile];
    [self pathForDataFile];
    [self pathForDatafolder1];
    [self pathForDatafolder2];
    
    PLog(@"Application did finish launching");
    hasFinishedLaunching = YES;

    // Create color:progressBar
    CIColor *color = [[CIColor alloc] initWithColor:[NSColor colorWithSRGBRed:0.8 green:0.8 blue:0.8 alpha:1]];
    // Create filter:progressBar
    CIFilter *colorFilter = [CIFilter filterWithName:@"CIFalseColor"
                                withInputParameters:@{@"inputColor0" : color,
                                                       @"inputColor1" : color}];
    // Assign to progressBar
    progressBarIndicator.contentFilters = @[colorFilter];
    
    /*if (promptForFileOnLaunch && acceptsFiles && [jobQueue count] == 0) {
        [self openFiles:self];
    } else {
        [self executeScript];
    }*/
}


#pragma mark - Interface actions


//Save the plist by adding a key
- (IBAction)savePlist1:(id)sender
{
    [ProgressIndicator setHidden:NO];
    [ProgressIndicator startAnimation:self];
        dispatch_queue_t backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(backgroundQueue, ^{
            for (NSUInteger i = 0; i < 1; i++) {
                [NSThread sleepForTimeInterval:0.8f];
            dispatch_async(dispatch_get_main_queue(), ^{
                [ProgressIndicator stopAnimation:self];
                [ProgressIndicator setHidden:YES];
            });
          }
      });
                
    self.ServerKey = [_ServerTextField stringValue];
    NSLog(@"text changed: %@", self.ServerKey);

    self.UserKey = [_UserTextField stringValue];

    self.PassKey = [_PassTextField stringValue];

    NSString * command = [NSString stringWithFormat:@"/usr/bin/security delete-generic-password -a ${USER} -s postftp 2>/dev/null | /usr/bin/security add-generic-password -a ${USER} -s postftp -w %@ 2>/dev/null", self.PassKey];
    NSTask *taskPass = [[NSTask alloc] init];
    [taskPass setLaunchPath:@"/bin/bash"];
    [taskPass setArguments:[NSArray arrayWithObjects: @"-c", command, nil]];
    [taskPass launch];
    
    NSMutableDictionary *root = [[NSMutableDictionary alloc] initWithContentsOfFile:self.plistFileName];
    [root setObject:self.ServerKey forKey:@"sr"];
    [root setObject:self.UserKey forKey:@"un"];

    NSLog(@"saving data:\n%@", root);
    NSError *error = nil;
    NSData *representation = [NSPropertyListSerialization dataWithPropertyList:root format:NSPropertyListBinaryFormat_v1_0 options:0 error:&error];
    if (!error)
    {
        BOOL ok = [representation writeToFile:self.plistFileName atomically:YES];
        if (ok)
        {
            NSLog(@"ok!");
        }
        else
        {
            NSLog(@"error writing to file: %@", self.plistFileName);
        }
    }
    else
    {
        NSLog(@"error: %@", error);
    }
}

- (IBAction)savePlist2:(id)sender
{
    [ProgressIndicatorPreset setHidden:NO];
    [ProgressIndicatorPreset startAnimation:self];
        dispatch_queue_t backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(backgroundQueue, ^{
            for (NSUInteger i = 0; i < 1; i++) {
                [NSThread sleepForTimeInterval:0.8f];
            dispatch_async(dispatch_get_main_queue(), ^{
                [ProgressIndicatorPreset stopAnimation:self];
                [ProgressIndicatorPreset setHidden:YES];
            });
          }
      });

    NSMutableDictionary *root = [[NSMutableDictionary alloc] initWithContentsOfFile:self.plistFileName];
    [root setObject:_currentlySelectedPort1 forKey:@"VEncoder"];
    [root setObject:_currentlySelectedPort2 forKey:@"AEncoder"];
    [root setObject:_currentlySelectedPort3 forKey:@"VBitRate"];
    [root setObject:_currentlySelectedPort4 forKey:@"Resolution"];
    [root setObject:_currentlySelectedPort5 forKey:@"Preset"];
    [root setObject:_currentlySelectedPort6 forKey:@"FrameRate"];
    [root setObject:_currentlySelectedPort7 forKey:@"Chroma"];
    [root setObject:_currentlySelectedPort8 forKey:@"ABitRate"];
    [root setObject:_currentlySelectedPort9 forKey:@"SampleRate"];
    [root setObject:_currentlySelectedPort10 forKey:@"Mode"];
    [root setObject:_currentlySelectedPort11 forKey:@"Channels"];
    [root setObject:_currentlySelectedPort12 forKey:@"AspectRatio"];
    [root setObject:self.InterlacedKey forKey:@"Interlaced"];
    [root setObject:self.WaitKey forKey:@"Wait"];
    [root setObject:self.XMLfileKey forKey:@"XMLfile"];

    NSLog(@"saving data:\n%@", root);
    NSError *error = nil;
    NSData *representation = [NSPropertyListSerialization dataWithPropertyList:root format:NSPropertyListBinaryFormat_v1_0 options:0 error:&error];
    if (!error)
    {
        BOOL ok = [representation writeToFile:self.plistFileName atomically:YES];
        if (ok)
        {
            NSLog(@"ok!");
        }
        else
        {
            NSLog(@"error writing to file: %@", self.plistFileName);
        }
    }
    else
    {
        NSLog(@"error: %@", error);
    }
}

- (IBAction)savePlist3:(id)sender {
    if ([sender state] == NSOffState) {
        [_CustomResolution setHidden:YES];
        if (![self.CustomRes isEqual: self.currentlySelectedPort4] && self.CustomRes != nil)
        {
            [ProgressIndicatorPreset setHidden:NO];
            [ProgressIndicatorPreset startAnimation:self];
            dispatch_queue_t backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
            dispatch_async(backgroundQueue, ^{
                for (NSUInteger i = 0; i < 1; i++) {
                    [NSThread sleepForTimeInterval:0.8f];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [ProgressIndicatorPreset stopAnimation:self];
                        [ProgressIndicatorPreset setHidden:YES];
                    });
                }
            });

            NSMutableDictionary *root = [[NSMutableDictionary alloc] initWithContentsOfFile:self.plistFileName];
            [root setObject:self.CustomRes forKey:@"Resolution"];
            NSError *error = nil;
            NSLog(@"ok!");
            NSLog(@"saving data:\n%@", root);
            NSData *representation = [NSPropertyListSerialization dataWithPropertyList:root format:NSPropertyListBinaryFormat_v1_0 options:0 error:&error];
            if (!error)
            {
                BOOL ok = [representation writeToFile:self.plistFileName atomically:YES];
                if (ok)
                {
                    NSLog(@"ok!");
                }
                else
                {
                    NSLog(@"error writing to file: %@", self.plistFileName);
                }
            }
            else
            {
                NSLog(@"error: %@", error);
            }
            
            NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
            NSString *plistPath = [rootPath stringByAppendingPathComponent:@"/Preferences/org.SerhiiHalan.SettingsFastLaunch.plist"];
            
            self.plistFileName = plistPath;
            NSLog(@"plist file path: %@", plistPath);
            //Получить ключи из плиста
            NSData *plistData = [NSData dataWithContentsOfFile:self.plistFileName];
            if (!plistData)
            {
                NSLog(@"error reading from file: %@", self.plistFileName);
            }
            NSPropertyListFormat format;
            id plist = [NSPropertyListSerialization propertyListWithData:plistData options:NSPropertyListMutableContainersAndLeaves format:&format error:&error];
            if (!error)
            {
                NSLog(@"loaded data:\n%@", root);
            }
            else
            {
                NSLog(@"error: %@", error);
            }
            _currentlySelectedPort4 = ((void)(@"%@"), [plist objectForKey:@"Resolution"]);
            [self.testArray4 addObject:@{ @"name" : self.CustomRes }];
        }
        else
         {
            NSLog(@"invalid parameters: %@", self.plistFileName);
          }
        }
    else {
        [_CustomResolution setHidden:NO];

        NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *plistPath = [rootPath stringByAppendingPathComponent:@"/Preferences/org.SerhiiHalan.SettingsFastLaunch.plist"];
        
        self.plistFileName = plistPath;
        NSLog(@"plist file path: %@", plistPath);

        //Получить ключи из плиста
        NSData *plistData = [NSData dataWithContentsOfFile:self.plistFileName];
        if (!plistData)
        {
            NSLog(@"error reading from file: %@", self.plistFileName);
        }
        NSPropertyListFormat format;
        NSError *error = nil;
        id plist = [NSPropertyListSerialization propertyListWithData:plistData options:NSPropertyListMutableContainersAndLeaves format:&format error:&error];
        if (!error)
        {
            NSMutableDictionary *root = plist;
            NSLog(@"loaded data:\n%@", root);
        }
        else
        {
            NSLog(@"error: %@", error);
        }
        _CustomRes = ((void)(@"%@"), [plist objectForKey:@"Resolution"]);
        self.CustomRes = _CustomRes;
    }
}

- (IBAction)savePlist4:(id)sender {
    if ([sender state] == NSOffState) {
        [_CustomVBitRate setHidden:YES];
        if (![self.CustomVBit isEqual: self.currentlySelectedPort3] && self.CustomVBit != nil)
        {
            [ProgressIndicatorPreset setHidden:NO];
            [ProgressIndicatorPreset startAnimation:self];
            dispatch_queue_t backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
            dispatch_async(backgroundQueue, ^{
                for (NSUInteger i = 0; i < 1; i++) {
                    [NSThread sleepForTimeInterval:0.8f];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [ProgressIndicatorPreset stopAnimation:self];
                        [ProgressIndicatorPreset setHidden:YES];
                    });
                }
            });

            NSMutableDictionary *root = [[NSMutableDictionary alloc] initWithContentsOfFile:self.plistFileName];
            [root setObject:self.CustomVBit forKey:@"VBitRate"];
            NSError *error = nil;
            NSLog(@"ok!");
            NSLog(@"saving data:\n%@", root);
            NSData *representation = [NSPropertyListSerialization dataWithPropertyList:root format:NSPropertyListBinaryFormat_v1_0 options:0 error:&error];
            if (!error)
            {
                BOOL ok = [representation writeToFile:self.plistFileName atomically:YES];
                if (ok)
                {
                    NSLog(@"ok!");
                }
                else
                {
                    NSLog(@"error writing to file: %@", self.plistFileName);
                }
            }
            else
            {
                NSLog(@"error: %@", error);
            }
            
            NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
            NSString *plistPath = [rootPath stringByAppendingPathComponent:@"/Preferences/org.SerhiiHalan.SettingsFastLaunch.plist"];
            
            self.plistFileName = plistPath;
            NSLog(@"plist file path: %@", plistPath);
            //Получить ключи из плиста
            NSData *plistData = [NSData dataWithContentsOfFile:self.plistFileName];
            if (!plistData)
            {
                NSLog(@"error reading from file: %@", self.plistFileName);
            }
            NSPropertyListFormat format;
            id plist = [NSPropertyListSerialization propertyListWithData:plistData options:NSPropertyListMutableContainersAndLeaves format:&format error:&error];
            if (!error)
            {
                NSLog(@"loaded data:\n%@", root);
            }
            else
            {
                NSLog(@"error: %@", error);
            }
            _currentlySelectedPort3 = ((void)(@"%@"), [plist objectForKey:@"VBitRate"]);
            [self.testArray3 addObject:@{ @"name" : self.CustomVBit }];
        }
        else
         {
            NSLog(@"invalid parameters: %@", self.plistFileName);
          }
        }
    else {
        [_CustomVBitRate setHidden:NO];

        NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *plistPath = [rootPath stringByAppendingPathComponent:@"/Preferences/org.SerhiiHalan.SettingsFastLaunch.plist"];
        
        self.plistFileName = plistPath;
        NSLog(@"plist file path: %@", plistPath);

        //Получить ключи из плиста
        NSData *plistData = [NSData dataWithContentsOfFile:self.plistFileName];
        if (!plistData)
        {
            NSLog(@"error reading from file: %@", self.plistFileName);
        }
        NSPropertyListFormat format;
        NSError *error = nil;
        id plist = [NSPropertyListSerialization propertyListWithData:plistData options:NSPropertyListMutableContainersAndLeaves format:&format error:&error];
        if (!error)
        {
            NSMutableDictionary *root = plist;
            NSLog(@"loaded data:\n%@", root);
        }
        else
        {
            NSLog(@"error: %@", error);
        }
        _CustomVBit = ((void)(@"%@"), [plist objectForKey:@"VBitRate"]);
        self.CustomVBit = _CustomVBit;
    }
}

- (IBAction)FolderPicker1:(id)sender{
    NSString *path = NSTemporaryDirectory();
    NSArray *directoryContents = [NSFileManager.defaultManager subpathsOfDirectoryAtPath:path error:nil];
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setTitle:@"Choose a Folder"];
    [openPanel setAllowedFileTypes:directoryContents];
    [openPanel setCanChooseDirectories:YES];    
    if ([openPanel runModal] == NSModalResponseOK){
        NSString *FolderPath = [[openPanel URLs][0] path];
        [FoldernameLabel1 setStringValue:FolderPath];
        NSMutableDictionary *root = [[NSMutableDictionary alloc] initWithContentsOfFile:self.plistFileName];
        self.Folder1 = [FoldernameLabel1 stringValue];
        if (![self.Folder1 isEqual: self.Folder2]){
            [root setObject:self.Folder1 forKey:@"MonitoringFolder"];
        }
        else
        {
            NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
            NSString *plistPath = [rootPath stringByAppendingPathComponent:@"/Preferences/org.SerhiiHalan.SettingsFastLaunch.plist"];
            self.plistFileName = plistPath;
            NSLog(@"plist file path: %@", plistPath);
            //Получить ключи из плиста
            NSData *plistData = [NSData dataWithContentsOfFile:self.plistFileName];
            if (!plistData)
            {
                NSLog(@"error reading from file: %@", self.plistFileName);
            }
            NSPropertyListFormat format;
            NSError *error = nil;
            id plist = [NSPropertyListSerialization propertyListWithData:plistData options:NSPropertyListMutableContainersAndLeaves format:&format error:&error];
            _Folder1 = ((void)(@"%@"), [plist objectForKey:@"MonitoringFolder"]);
            self.Folder1 = _Folder1;
        }
    
        NSLog(@"saving data:\n%@", root);
        NSError *error = nil;
        NSData *representation = [NSPropertyListSerialization dataWithPropertyList:root format:NSPropertyListBinaryFormat_v1_0 options:0 error:&error];
        if (!error)
        {
            BOOL ok = [representation writeToFile:self.plistFileName atomically:YES];
            if (ok)
            {
                NSLog(@"ok!");
            }
            else
            {
                NSLog(@"error writing to file: %@", self.plistFileName);
            }
        }
        else
        {
            NSLog(@"error: %@", error);
        }
    }
}

- (IBAction)FolderPicker2:(id)sender{
    NSString *path = NSTemporaryDirectory();
    NSArray *directoryContents = [NSFileManager.defaultManager subpathsOfDirectoryAtPath:path error:nil];
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setTitle:@"Choose a Folder"];
    [openPanel setAllowedFileTypes:directoryContents];
    [openPanel setCanChooseDirectories:YES];
    if ([openPanel runModal] == NSModalResponseOK){
        NSString *FolderPath = [[openPanel URLs][0] path];
        [FoldernameLabel2 setStringValue:FolderPath];
        NSMutableDictionary *root = [[NSMutableDictionary alloc] initWithContentsOfFile:self.plistFileName];
        self.Folder2 = [FoldernameLabel2 stringValue];
        if (![self.Folder1 isEqual: self.Folder2]){
            [root setObject:self.Folder2 forKey:@"DestinationFolder"];
        }
        else
        {
            NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
            NSString *plistPath = [rootPath stringByAppendingPathComponent:@"/Preferences/org.SerhiiHalan.SettingsFastLaunch.plist"];
            self.plistFileName = plistPath;
            NSLog(@"plist file path: %@", plistPath);
            //Получить ключи из плиста
            NSData *plistData = [NSData dataWithContentsOfFile:self.plistFileName];
            if (!plistData)
            {
                NSLog(@"error reading from file: %@", self.plistFileName);
            }
            NSPropertyListFormat format;
            NSError *error = nil;
            id plist = [NSPropertyListSerialization propertyListWithData:plistData options:NSPropertyListMutableContainersAndLeaves format:&format error:&error];
            _Folder2 = ((void)(@"%@"), [plist objectForKey:@"DestinationFolder"]);
            self.Folder2 = _Folder2;
        }
            NSLog(@"saving data:\n%@", root);
        NSError *error = nil;
        NSData *representation = [NSPropertyListSerialization dataWithPropertyList:root format:NSPropertyListBinaryFormat_v1_0 options:0 error:&error];
        if (!error)
        {
            BOOL ok = [representation writeToFile:self.plistFileName atomically:YES];
            if (ok)
            {
                NSLog(@"ok!");
            }
            else
            {
                NSLog(@"error writing to file: %@", self.plistFileName);
            }
        }
        else
        {
            NSLog(@"error: %@", error);
        }
    }
}

// Run open panel, made available to apps that accept files
- (IBAction)openFiles:(id)sender {
    
    // Create open panel
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    [oPanel setAllowsMultipleSelection:YES];
    [oPanel setCanChooseFiles:YES];
    [oPanel setCanChooseDirectories:acceptDroppedFolders];
    
    if ([oPanel runModal] == NSModalResponseOK) {
        // Convert URLs to paths
        NSMutableArray *filePaths = [NSMutableArray array];
        for (NSURL *url in [oPanel URLs]) {
            [filePaths addObject:[url path]];
        }
        
        BOOL success = [self addDroppedFilesJob:filePaths];
        
        if (!isTaskRunning && success) {
            [self executeScript];
            [self executeScript1];
        }
        
    } else {
        // Canceled in open file dialog
        if (!remainRunning) {
            [[NSApplication sharedApplication] terminate:self];
        }
    }
}

// Show / hide the details text field in progress bar2 interface
- (IBAction)toggleDetails:(id)sender {
            NSRect winRect = [FastLaunchWindow frame];
            NSSize minSize = [FastLaunchWindow minSize];
            NSSize maxSize = [FastLaunchWindow maxSize];
            
        if ([sender state] == NSOffState) {
            winRect.origin.y += detailsHeight;
            winRect.size.height -= detailsHeight;
            minSize.height -= detailsHeight;
            maxSize.height -= detailsHeight;

        }
        else {
            winRect.origin.y -= detailsHeight;
            winRect.size.height += detailsHeight;
            minSize.height += detailsHeight;
            maxSize.height += detailsHeight;
        }
            
            [DEFAULTS setBool:([sender state] == NSOnState) forKey:@"UserShowDetails"];
            [FastLaunchWindow setMinSize:minSize];
            [FastLaunchWindow setMaxSize:maxSize];
            [FastLaunchWindow setShowsResizeIndicator:([sender state] == NSOnState)];
            [FastLaunchWindow setFrame:winRect display:TRUE animate:TRUE];
    }

// Show the details text field in progress bar2 interface
- (IBAction)showDetails {
    if ([DetailsTriangle state] == NSOffState) {
        [DetailsTriangle performClick:DetailsTriangle];
    }
 }

// Hide the details text field in progress bar2 interface
- (IBAction)hideDetails {
      if ([DetailsTriangle state] != NSOffState) {
        [DetailsTriangle performClick:DetailsTriangle];
    }
 }

- (BOOL)validateMenuItem:(NSMenuItem *)anItem {

    SEL selector = [anItem action];
    // Open should only work if it's a droppable app that accepts files
    if (acceptsFiles && selector == @selector(openFiles:)) {
        return YES;
    }

    if ([anItem action] == @selector(savePlist2:)) {
        return YES;
    }
    
    if ([anItem action] == @selector(buttonDonations:)) {
        return YES;
    }
    
    if ([anItem action] == @selector(menuItemSelected:)) {
        return YES;
    }
    
    return NO;
}

- (IBAction)cancel:(id)sender {
    if (task != nil && [task isRunning]) {
        PLog(@"Task cancelled");
        [task terminate];
        jobQueue = [NSMutableArray array];
    }

    if ([[sender title] isEqualToString:@"Quit"]) {
        [[NSApplication sharedApplication] terminate:self];
    }
}

- (IBAction)buttonClick:(id)sender {
    [self executeScript1];
    [myImageView setImage:nil];
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification {
    return sendsNotifications;
}

- (void)application:(NSApplication *)theApplication openFiles:(NSArray *)filenames {
    PLog(@"Received openFiles event for files: %@", [filenames description]);
    
    if (hasTaskRun == FALSE && commandLineArguments != nil) {
        for (NSString *filePath in filenames) {
            if ([commandLineArguments containsObject:filePath]) {
                return;
            }
        }
    }
    
    // Add the dropped files as a job for processing
    BOOL success = [self addDroppedFilesJob:filenames];
    [NSApp replyToOpenOrPrint:success ? NSApplicationDelegateReplySuccess : NSApplicationDelegateReplyFailure];
    
    // If no other job is running, we execute
    if (success && !isTaskRunning && hasFinishedLaunching) {
        [self executeScript];
    }
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    // Terminate task
    if (task != nil) {
        if ([task isRunning]) {
            [task terminate];
        }
        task = nil;
    }
    return NSTerminateNow;
}

#pragma mark - Interface manipulation

// Set up any menu items, windows, controls at application launch
- (void)initialiseInterface {
    [openRecentMenuItem setEnabled:acceptsFiles];
    if (!acceptsFiles) {
        [fileMenu removeItemAtIndex:0]; // Open
        [fileMenu removeItemAtIndex:0]; // Open Recent..
        [fileMenu removeItemAtIndex:0]; // Separator
    }

    // Script output will be dumped in outputTextView
    // By default this is the Text Window text view

    if (runInBackground == TRUE) {
        // Old Carbon way
        [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    }
    
                if (isDroppable) {
                    [FastLaunchWindow registerForDraggedTypes:@[NSFilenamesPboardType, NSStringPboardType]];
                }
                
                if ([DEFAULTS boolForKey:@"UserShowDetails"]) {
                    NSRect frame = [FastLaunchWindow frame];
                    frame.origin.y += detailsHeight;
                    [FastLaunchWindow setFrame:frame display:NO];
                   [self showDetails];
               }
                
                [FastLaunchWindow makeKeyAndOrderFront:self];
}

// Prepare all the controls, windows, etc prior to executing script
- (void)prepareInterfaceForExecution {
    [outputTextView setString:@""];
    // Yes, yes, this is a nasty hack. But styling in NSTextViews
    // doesn't get applied when appending text unless there is already
    // some text in the view. The alternative is to make very expensive
    // calls to [textStorage setAttributes:] for all appended output,
    // which freezes up the app when lots of text is dumped by the script
    [outputTextView setString:@"\u200B"]; // zero-width space character
    
    [CancelButton setTitle:@"Cancel"];
    [savePlist1 setEnabled:NO];
    [savePlist1a setEnabled:NO];
    [savePlist1b setEnabled:NO];
    [FolderPicker1 setEnabled:NO];
    [FolderPicker2 setEnabled:NO];
    [[DockProgressBarRed sharedDockProgressBarRed] clearRed];
    [myImageView setImage:nil];
    self.FileString = nil;
    self.SecondsString = nil;
    self.OnlyString = nil;
    // Create color:progressBar
    CIColor *color = [[CIColor alloc] initWithColor:[NSColor colorWithSRGBRed:0.8 green:0.8 blue:0.8 alpha:1]];
    // Create filter:progressBar
    CIFilter *colorFilter = [CIFilter filterWithName:@"CIFalseColor"
                                withInputParameters:@{@"inputColor0" : color,
                                                       @"inputColor1" : color}];
    // Assign to progressBar
    progressBarIndicator.contentFilters = @[colorFilter];
    [progressBarIndicator setDoubleValue:0];
}

// Adjust controls, windows, etc. once script is done executing
- (void)cleanupInterface {

    [CancelButton setTitle:@"Quit"];
    [CancelButton setEnabled:YES];
    [savePlist1 setEnabled:YES];
    [savePlist1a setEnabled:YES];
    [savePlist1b setEnabled:YES];
    [FolderPicker1 setEnabled:YES];
    [FolderPicker2 setEnabled:YES];
}

#pragma mark - Task

// Construct arguments list etc. before actually running the script

- (void)prepareForExecution {
    
    // Clear arguments list and reconstruct it
    [arguments removeAllObjects];
    
    // First, add all specified arguments for interpreter
    [arguments addObjectsFromArray:interpreterArgs];
    
    // Add script as argument to interpreter, if it exists
    if (![FILEMGR fileExistsAtPath:scriptDropPath]) {
        NSLog(@"Script missing at execution path %@", scriptDropPath);
    }
    [arguments addObject:scriptDropPath];
    
    // Add arguments for script
    [arguments addObjectsFromArray:scriptArgs];
    
    // If initial run of app, add any arguments passed in via the command line (argv)
    // Q: Why CLI args for GUI app typically launched from Finder?
    // A: Apparently helpful for certain use cases such as Firefox protocol handlers etc.
    if (commandLineArguments && [commandLineArguments count]) {
        [arguments addObjectsFromArray:commandLineArguments];
        commandLineArguments = nil;
    }
    
    // Finally, dequeue job and add arguments
    if ([jobQueue count] > 0) {
        FastLaunchJob *job = jobQueue[0];

        // We have files in the queue, to append as arguments
        // We take the first job's arguments and put them into the arg list
        if ([job arguments]) {
            [arguments addObjectsFromArray:[job arguments]];
        }
        stdinString = [[job standardInputString] copy];
        
        [jobQueue removeObjectAtIndex:0];
    }
}

- (void)prepareForExecution1 {
    
    // Clear arguments list and reconstruct it
    [arguments removeAllObjects];
    
    // First, add all specified arguments for interpreter
    [arguments addObjectsFromArray:interpreterArgs];

    // Add script1 as argument to interpreter, if it exists
    if (![FILEMGR fileExistsAtPath:scriptStartPath]) {
        NSLog(@"Script missing at execution path %@", scriptStartPath);
    }
    [arguments addObject:scriptStartPath];
    
    // Add arguments for script1
    [arguments addObjectsFromArray:script1Args];
    
    // If initial run of app, add any arguments passed in via the command line (argv)
    // Q: Why CLI args for GUI app typically launched from Finder?
    // A: Apparently helpful for certain use cases such as Firefox protocol handlers etc.
    if (commandLineArguments && [commandLineArguments count]) {
        [arguments addObjectsFromArray:commandLineArguments];
        commandLineArguments = nil;
    }
    
    // Finally, dequeue job and add arguments
    if ([jobQueue count] > 0) {
        FastLaunchJob *job = jobQueue[0];

        // We have files in the queue, to append as arguments
        // We take the first job's arguments and put them into the arg list
        if ([job arguments]) {
            [arguments addObjectsFromArray:[job arguments]];
        }
        stdinString = [[job standardInputString] copy];
        
        [jobQueue removeObjectAtIndex:0];
    }
}


- (void)executeScript {
    hasTaskRun = YES;
    
    // Never execute script if there is one running
    if (isTaskRunning) {
        return;
    }
    outputEmpty = NO;
    
    [self prepareForExecution];
    [self prepareInterfaceForExecution];
    
    isTaskRunning = YES;
    
    // Run the task
        [self executeScriptWithoutPrivileges];
}

- (void)executeScript1 {
    hasTaskRun = YES;
    
    // Never execute script1 if there is one running
    if (isTaskRunning) {
        return;
    }
    outputEmpty = NO;
    
    [self prepareForExecution1];
    [self prepareInterfaceForExecution];
    
    isTaskRunning = YES;
    
    // Run the task
        [self executeScriptWithoutPrivileges];
}


// Launch regular user-privileged process using NSTask
- (void)executeScriptWithoutPrivileges {

    // Create task and apply settings
    task = [[NSTask alloc] init];
    [task setLaunchPath:interpreterPath];
    [task setCurrentDirectoryPath:[[NSBundle mainBundle] resourcePath]];
    [task setArguments:arguments];
    
    // Direct output to file handle and start monitoring it if script provides feedback
    outputPipe = [NSPipe pipe];
    [task setStandardOutput:outputPipe];
    [task setStandardError:outputPipe];
    outputReadFileHandle = [outputPipe fileHandleForReading];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gotOutputData:) name:NSFileHandleReadCompletionNotification object:outputReadFileHandle];
    [outputReadFileHandle readInBackgroundAndNotify];
    
    // Set up stdin for writing
    inputPipe = [NSPipe pipe];
    [task setStandardInput:inputPipe];
    inputWriteFileHandle = [[task standardInput] fileHandleForWriting];
    
    // Set it off
    //PLog(@"Running task\n%@", [task humanDescription]);
    [task launch];
    
    // Write input, if any, to stdin, and then close
    if (stdinString) {
        [inputWriteFileHandle writeData:[stdinString dataUsingEncoding:NSUTF8StringEncoding]];
    }
    [inputWriteFileHandle closeFile];
    stdinString = nil;    
}


#pragma mark - Task completion

// OK, called when we receive notification that task is finished
// Some cleaning up to do, controls need to be adjusted, etc.
- (void)taskFinished:(NSNotification *)aNotification {
    isTaskRunning = NO;
    PLog(@"Task finished");
    
    // Did we receive all the data?
    // If no data left, we do clean up
    if (outputEmpty) {
        [self cleanup];
    }
    
    // If there are more jobs waiting for us, execute
    if ([jobQueue count] > 0 /*&& remainRunning*/) {
        [self executeScript];
    }
}

- (void)cleanup {
    if (isTaskRunning) {
        return;
    }
    // Stop observing the filehandle for data since task is done
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSFileHandleReadCompletionNotification
                                                  object:outputReadFileHandle];
    
    // We make sure to clear the filehandle of any remaining data
    if (outputReadFileHandle != nil) {
        NSData *data;
        while ((data = [outputReadFileHandle availableData]) && [data length]) {
            [self parseOutput:data];
        }
    }
    
    // Now, reset all controls etc., general cleanup since task is done
    [self cleanupInterface];
}

#pragma mark - Output

// Read from the file handle and append it to the text window
- (void)gotOutputData:(NSNotification *)aNotification {
    // Get the data from notification
    NSData *data = [aNotification userInfo][NSFileHandleNotificationDataItem];
    
    // Make sure there's actual data
    if ([data length]) {
        outputEmpty = NO;
        
        // Append the output to the text field
        [self parseOutput:data];
        
        // We schedule the file handle to go and read more data in the background again.
        [[aNotification object] readInBackgroundAndNotify];
    }
    else {
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


- (void)parseOutput:(NSData *)data {
    // Create string from output data
    NSMutableString *outputString = [[NSMutableString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    if (outputString == nil) {
        PLog(@"Warning: Output string is nil");
        return;
    }
    
    PLog(@"Output:%@", outputString);
    
    if (remnants) {
        [outputString insertString:remnants atIndex:0];
    }
    
    // Parse line by line
    NSMutableArray *lines = [[outputString componentsSeparatedByString:@"\n"] mutableCopy];
    
    // If the string did not end with a newline, it wasn't a complete line of output
    // Thus, we store this last non-newline-terminated string
    // It'll be prepended next time we get output
    if ([[lines lastObject] length] > 0) { // Output didn't end with a newline
        remnants = [lines lastObject];
    } else {
        remnants = nil;
    }
    
    [lines removeLastObject];
    
    // Parse output looking for commands; if none, append line to output text field
    for (NSString *theLine in lines) {
        
        
        //        if ([theLine length] == 0) {
        //            [self appendString:@""];
        //            continue;
        //        }
        
        
        //Слайды на экране
        if (![self.SecondsString isEqual: self.SecondsStringOld] && ![_FileString  isEqual: @""]) {
            NSString *urlString = [self.FileString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]]; //декодирование кириллического URL
            NSURL *videoURL = [NSURL URLWithString:urlString];
            AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoURL options:nil];
            AVAssetImageGenerator* imgGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
            
            imgGenerator.appliesPreferredTrackTransform = YES;
            imgGenerator.requestedTimeToleranceBefore = kCMTimeZero;
            imgGenerator.requestedTimeToleranceAfter = kCMTimeZero;
            imgGenerator.maximumSize = CGSizeMake(340, 192);
            imgGenerator.apertureMode = AVAssetImageGeneratorApertureModeProductionAperture;
            
            Float64 Seconds = [self.SecondsString floatValue];
            CMTime time = CMTimeMakeWithSeconds(Seconds, 1);
            //    CMTimeShow(time);

            NSError *error;
            CGImageRef imageRef = [imgGenerator copyCGImageAtTime:time actualTime:NULL error:NULL];
            if (!imageRef) {
                NSLog(@"AVAssetImageGenerator frame generate failed: %@", error);
                NSImage* thumbnail = [[NSImage alloc]initWithContentsOfFile:@"/private/tmp/img.jpeg"];
                [myImageView setImage:thumbnail];
            } else {
                NSImage* thumbnail = [[NSImage alloc] initWithCGImage:imageRef size:NSMakeSize(340, 192)];
                [myImageView setImage:thumbnail];
                _SecondsStringOld = self.SecondsString;
            }
        } else{
            NSLog(@"Skip image building");
            
        }
        
        
        if ([theLine hasPrefix:@"NOTIFICATION:"]) {
            NSString *notificationString = [theLine substringFromIndex:13];
            [self showNotification:notificationString];
            continue;
        }
        
        
        if ([theLine hasPrefix:@"Name:"]) {
            NSString *NameString = [theLine substringFromIndex:5];
            if ([NameString hasSuffix:@"%"]) {
                NameString = [NameString substringToIndex:[NameString length]-1];
            }
            [MessageTextFieldName setStringValue:NameString];
            continue;
        }
        
        
        if ([theLine hasPrefix:@"ONLY:"]) {
            NSString *OnlyString = [theLine substringFromIndex:5];
            if ([OnlyString hasSuffix:@"%"]) {
                OnlyString = [OnlyString substringToIndex:[OnlyString length]-1];
            }
            self.OnlyString = OnlyString;
            continue;
        }
        
        
        if ([theLine hasPrefix:@"Progress:"]) {
            NSString *ProgressString = [theLine substringFromIndex:9];
            if ([ProgressString hasSuffix:@"%"]) {
                ProgressString = [ProgressString substringToIndex:[ProgressString length]-1];
            }
            [MessageTextFieldProgress setStringValue:ProgressString];
            self.ProgressString = ProgressString;
            if ([self.OnlyString  isEqual: @"RED"]) {
                if (ProgressString != nil) {
                    double progressRed = [ProgressString intValue]/100.0;
                    // Make sure the previous ProgressBar is clear before update.
                    [[DockProgressBarRed sharedDockProgressBarRed]
                     setProgressRed:(float)progressRed];
                    [[DockProgressBarRed sharedDockProgressBarRed] updateProgressBarRed];
                    [[DockProgressBarBlue sharedDockProgressBarBlue] hideProgressBarBlue];
                    // Create color:ProgressBar
                    CIColor *color = [[CIColor alloc] initWithColor:[NSColor colorWithSRGBRed:1 green:0.1 blue:0.1 alpha:1]];
                    // Create filter:ProgressBar
                    CIFilter *colorFilter = [CIFilter filterWithName:@"CIFalseColor"
                                                withInputParameters:@{@"inputColor0" : color,
                                                                       @"inputColor1" : color}];
                    // Assign to ProgressBar
                    progressBarIndicator.contentFilters = @[colorFilter];
                    double progressBarRed = [ProgressString intValue];
                    [progressBarIndicator setIndeterminate:NO];
                    [progressBarIndicator setDoubleValue:progressBarRed];
                }
            }
            else if ([self.OnlyString  isEqual: @"BLUE"]) {
                if (ProgressString != nil) {
                    double progressBlue = [ProgressString intValue]/100.0;
                    // Make sure the previous ProgressBar is clear before update.
                    [[DockProgressBarBlue sharedDockProgressBarBlue]
                     setProgressBlue:(float)progressBlue];
                    [[DockProgressBarBlue sharedDockProgressBarBlue] updateProgressBarBlue];
                    [[DockProgressBarRed sharedDockProgressBarRed] hideProgressBarRed];
                    // Create color:ProgressBar
                    CIColor *color = [[CIColor alloc] initWithColor:[NSColor colorWithSRGBRed:0.1 green:0.6 blue:1 alpha:1]];
                    // Create filter:ProgressBar
                    CIFilter *colorFilter = [CIFilter filterWithName:@"CIFalseColor"
                                                withInputParameters:@{@"inputColor0" : color,
                                                                       @"inputColor1" : color}];
                    // Assign to ProgressBar
                    progressBarIndicator.contentFilters = @[colorFilter];
                    double progressBarBlue = [ProgressString intValue];
                    [progressBarIndicator setIndeterminate:NO];
                    [progressBarIndicator setDoubleValue:progressBarBlue];
                }
            }
            if ([self.ProgressString  isEqual: @"0% "]) {
                [[DockProgressBarRed sharedDockProgressBarRed] clearRed];
            }
            continue;
        }
        
        
        if ([theLine hasPrefix:@"FPS:"]) {
            NSString *FPSString = [theLine substringFromIndex:4];
            if ([FPSString hasSuffix:@"%"]) {
                FPSString = [FPSString substringToIndex:[FPSString length]-1];
            }
            [MessageTextFieldFPS setStringValue:FPSString];
            continue;
        }
        
        
        if ([theLine hasPrefix:@"Size:"]) {
            NSString *SizeString = [theLine substringFromIndex:5];
            if ([SizeString hasSuffix:@"%"]) {
                SizeString = [SizeString substringToIndex:[SizeString length]-1];
            }
            [MessageTextFieldSize setStringValue:SizeString];
            continue;
        }
        
        
        if ([theLine hasPrefix:@"Duration:"]) {
            NSString *DurationString = [theLine substringFromIndex:9];
            if ([DurationString hasSuffix:@"%"]) {
                DurationString = [DurationString substringToIndex:[DurationString length]-1];
            }
            [MessageTextFieldDuration setStringValue:DurationString];
            continue;
        }
        
        
        if ([theLine hasPrefix:@"Time:"]) {
            NSString *TimeString = [theLine substringFromIndex:5];
            if ([TimeString hasSuffix:@"%"]) {
                TimeString = [TimeString substringToIndex:[TimeString length]-1];
            }
            [MessageTextFieldTime setStringValue:TimeString];
            continue;
        }
        
        
        if ([theLine hasPrefix:@"Speed:"]) {
            NSString *SpeedString = [theLine substringFromIndex:6];
            if ([SpeedString hasSuffix:@"%"]) {
                SpeedString = [SpeedString substringToIndex:[SpeedString length]-1];
            }
            [MessageTextFieldSpeed setStringValue:SpeedString];
            continue;
        }
        
        
        if ([theLine hasPrefix:@"Media:"]) {
            NSString *MediaString = [theLine substringFromIndex:6];
            if ([MediaString hasSuffix:@"%"]) {
                MediaString = [MediaString substringToIndex:[MediaString length]-1];
            }
            [MessageTextFieldMediaInfo setStringValue:MediaString];
            continue;
        }
        
        
        if ([theLine hasPrefix:@"Files:"]) {
            NSString *FileString = [theLine substringFromIndex:6];
            if ([FileString hasSuffix:@"%"]) {
                FileString = [FileString substringToIndex:[FileString length]-1];
            }
            self.FileString = FileString;
            continue;
        }
        
        
        if ([theLine hasPrefix:@"Seconds:"]) {
            NSString *SecondsString = [theLine substringFromIndex:8];
            if ([SecondsString hasSuffix:@"%"]) {
                SecondsString = [SecondsString substringToIndex:[SecondsString length]-1];
            }
            self.SecondsString = SecondsString;
            continue;
        }
        
        
        if ([theLine hasPrefix:@"Info:"]) {
            NSString *InfoString = [theLine substringFromIndex:5];
            if ([InfoString hasSuffix:@"%"]) {
                InfoString = [InfoString substringToIndex:[InfoString length]-1];
            }
            [MessageTextFieldInfo setStringValue:InfoString];
            continue;
        }

        
        else if ([self.OnlyString  isEqual: @"RED"]) {
            [CancelButton setTitle:@"Cancel"];
            continue;
        }
        else if ([self.OnlyString  isEqual: @"BLUE"]) {
            [CancelButton setTitle:@"Pause"];
            continue;
        }
    }
}

- (void)clearOutputBuffer {
    NSTextStorage *textStorage = [outputTextView textStorage];
    NSRange range = NSMakeRange(0, [textStorage length]-1);
    [textStorage beginEditing];
    [textStorage replaceCharactersInRange:range withString:@""];
    [textStorage endEditing];
}


#pragma mark - Service handling

- (void)dropService:(NSPasteboard *)pb userData:(NSString *)userData error:(NSString **)err {
    PLog(@"Received drop service data");
    NSArray *types = [pb types];
    BOOL ret = 0;
    id data = nil;
    
    if (acceptsFiles && [types containsObject:NSFilenamesPboardType] && (data = [pb propertyListForType:NSFilenamesPboardType])) {
        ret = [self addDroppedFilesJob:data];  // Files
    } else {
        // Unknown
        *err = @"Data type in pasteboard cannot be handled by this application.";
        return;
    }
    
    if (isTaskRunning == NO && ret) {
        [self executeScript];
    }
}

#pragma mark - Add job to queue

// Processing dropped files
- (BOOL)addDroppedFilesJob:(NSArray <NSString *> *)files {
    if (!acceptsFiles) {
        return NO;
    }
    
    // We only accept the drag if at least one of the files meets the required types
    NSMutableArray *acceptedFiles = [NSMutableArray array];
    for (NSString *file in files) {
        if ([self isAcceptableFileType:file]) {
            [acceptedFiles addObject:file];
        }
    }
    if ([acceptedFiles count] == 0) {
        return NO;
    }
    
    // We create a job and add the files as arguments
    FastLaunchJob *job = [FastLaunchJob jobWithArguments:acceptedFiles andStandardInput:nil];
    [jobQueue addObject:job];
    
    // Add to Open Recent menu
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


- (BOOL)isAcceptableFileType:(NSString *)file {
    
    // Check if it's a folder. If so, we only accept it if folders are accepted
    BOOL isDir;
    BOOL exists = [FILEMGR fileExistsAtPath:file isDirectory:&isDir];
    if (!exists) {
        return NO;
    }
    if (isDir) {
        return acceptDroppedFolders;
    }
    
    if (acceptAnyDroppedItem) {
        return YES;
    }
    return NO;
}

#pragma mark - Drag and drop handling

// Check file types against acceptable drop types here before accepting them
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    // Prevent dragging from NSOpenPanels
    // draggingSource returns nil if the source is not in the same application
    // as the destination. We decline any drags from within the app.
    if ([sender draggingSource]) {
        return NSDragOperationNone;
    }
    
    BOOL acceptDrag = NO;
    NSPasteboard *pboard = [sender draggingPasteboard];
    
    // String dragged
    if ([[pboard types] containsObject:NSStringPboardType] && acceptsText) {
        acceptDrag = YES;
    }
    // File dragged
    else if ([[pboard types] containsObject:NSFilenamesPboardType] && acceptsFiles) {
        // Loop through files, see if any of the dragged files are acceptable
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
        
        for (NSString *file in files) {
            if ([self isAcceptableFileType:file]) {
                acceptDrag = YES;
                break;
            }
        }
    }
    
    if (acceptDrag) {
        PLog(@"Dragged items accepted");
        return NSDragOperationLink;
    }
    
    PLog(@"Dragged items refused");
    return NSDragOperationNone;
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender {
    return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard = [sender draggingPasteboard];
    
    // Determine drag data type and dispatch to job queue
    if ([[pboard types] containsObject:NSFilenamesPboardType]) {
        return [self addDroppedFilesJob:[pboard propertyListForType:NSFilenamesPboardType]];
    }
    return NO;
}

// Once the drag is over, we immediately execute w. files as arguments if not already processing
- (void)concludeDragOperation:(id <NSDraggingInfo>)sender {

    // Fire off the job queue if nothing is running
    if (!isTaskRunning && [jobQueue count] > 0) {
        [NSTimer scheduledTimerWithTimeInterval:0.0f target:self selector:@selector(executeScript) userInfo:nil repeats:NO];
        [NSTimer scheduledTimerWithTimeInterval:0.0f target:self selector:@selector(executeScript1) userInfo:nil repeats:NO];
    }
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender {
    // This is needed to keep link instead of the green plus sign on web view
    // and also required to reject non-acceptable dragged items.
    return [self draggingEntered:sender];
}

- (IBAction)menuItemSelected:(id)sender {
    [self addMenuItemSelectedJob:[sender title]];
    if (!isTaskRunning && [jobQueue count] > 0) {
        [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(executeScript) userInfo:nil repeats:NO];
        [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(executeScript1) userInfo:nil repeats:NO];
    }
}

#pragma mark - Utility methods

- (void)showNotification:(NSString *)notificationText {
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    [notification setInformativeText:notificationText];
    [notification setSoundName:NSUserNotificationDefaultSoundName];
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}

// Donations
- (IBAction)buttonDonations:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=2BREZMHRLQNZ4&source=url"]];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    return YES;
}

@end



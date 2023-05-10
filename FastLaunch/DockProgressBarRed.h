#import <Cocoa/Cocoa.h>

@interface DockProgressBarRed : NSProgressIndicator

+ (DockProgressBarRed*)sharedDockProgressBarRed;

- (void)setProgressRed:(float)progressRed;

- (void)updateProgressBarRed;

- (void)hideProgressBarRed;

- (void)clearRed;

@end

#import <Cocoa/Cocoa.h>

@interface DockProgressBarBlue : NSProgressIndicator

+ (DockProgressBarBlue*)sharedDockProgressBarBlue;

- (void)setProgressBlue:(float)progressBlue;

- (void)updateProgressBarBlue;

- (void)hideProgressBarBlue;

- (void)clearBlue;

@end

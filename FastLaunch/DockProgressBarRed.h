#import <Cocoa/Cocoa.h>
//
//  DockProgressBarRed.h
//  FastLaunch
//
//  Created by Sergey Galan.
//  Copyright © 2020-2025 Sergey Galan. All rights reserved.
//

@interface DockProgressBarRed : NSProgressIndicator

+ (DockProgressBarRed*)sharedDockProgressBarRed;

- (void)setProgressRed:(float)progressRed;

- (void)updateProgressBarRed;

- (void)hideProgressBarRed;

- (void)clearRed;

@end

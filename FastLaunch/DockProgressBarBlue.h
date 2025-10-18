#import <Cocoa/Cocoa.h>
//
//  DockProgressBarBlue.h
//  FastLaunch
//
//  Created by Sergey Galan.
//  Copyright © 2020-2025 Sergey Galan. All rights reserved.
//

@interface DockProgressBarBlue : NSProgressIndicator

+ (DockProgressBarBlue*)sharedDockProgressBarBlue;

- (void)setProgressBlue:(float)progressBlue;

- (void)updateProgressBarBlue;

- (void)hideProgressBarBlue;

- (void)clearBlue;

@end

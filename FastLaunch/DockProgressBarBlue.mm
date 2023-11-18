#import "DockProgressBarBlue.h"

@implementation DockProgressBarBlue

+ (DockProgressBarBlue*)sharedDockProgressBarBlue {
  static DockProgressBarBlue* progress_bar;
  NSDockTile* dock_tile = [NSApp dockTile];
  if (!progress_bar) {
    progress_bar = [[DockProgressBarBlue alloc] initWithFrame:
                     NSMakeRect(0.0f, 0.0f, dock_tile.size.width, 15.0f)];
    [progress_bar setStyle:NSProgressIndicatorStyleBar];
    [progress_bar setIndeterminate:NO];
    [progress_bar setBezeled:YES];
    [progress_bar setMinValue:0];
    [progress_bar setMaxValue:1];
    [progress_bar setHidden:NO];
  }
  if ([dock_tile contentView] == NULL) {
    NSImageView* content_view = [[NSImageView alloc] init];
    [content_view setImage:[NSApp applicationIconImage]];
    [dock_tile setContentView:content_view];
    [content_view addSubview:progress_bar];
  }
  return progress_bar;
}

- (void)drawRect:(NSRect)dirtyRect {
  // Draw edges of rounded rect.
  NSRect rect = NSInsetRect([self bounds], 1.0, 1.0);
  CGFloat radius = rect.size.height / 1;
  NSBezierPath* bezier_path = [NSBezierPath bezierPathWithRoundedRect:rect
                                            xRadius:radius
                                            yRadius:radius];
  [bezier_path setLineWidth:1.0];
  [[NSColor grayColor] set];
  [bezier_path stroke];

  // Fill the rounded rect.
  rect = NSInsetRect(rect, 1.0, 1.0);
  radius = rect.size.height / 1;
  bezier_path = [NSBezierPath bezierPathWithRoundedRect:rect xRadius:radius yRadius:radius];
  [bezier_path setLineWidth:1.0];
  [bezier_path addClip];
  
  // Calculate the progress width.
  rect.size.width = floor(rect.size.width * ([self doubleValue] / [self maxValue]));
  
  // Fill the progress bar with color blue.
    [[NSColor colorWithSRGBRed:0.1 green:0.6 blue:1 alpha:1] set];
  NSRectFill(rect);
}

- (void)updateProgressBarBlue {
  [self setHidden:NO];
  [[NSApp dockTile] display];
}

- (void)hideProgressBarBlue {
  [self setHidden:YES];
  [[NSApp dockTile] display];
}

- (void)setProgressBlue:(float)progressBlue {
  [self setDoubleValue:progressBlue];
}

- (void)clearBlue {
  [[NSApp dockTile] setContentView:NULL];
}

@end

/*
 
 Transcribbler, a Mac OS X text editor for audio/video transcription
 Copyright (C) 2013  Eli Bishop
 
 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 as published by the Free Software Foundation; either version 2
 of the License, or (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 
 */

#import "StackingView.h"
#import "ViewSizeLimits.h"


@interface StackingViewSubviewInfo : NSObject {
 @public
  NSView* view;
  NSUInteger options;
}
@end

@implementation StackingViewSubviewInfo
@end


@implementation StackingView

- (id)initWithFrame:(NSRect)r
{
  self = [super initWithFrame:r];
  inited = NO;
  updating = NO;
  return self;
}

- (void)awakeFromNib
{
  inited = YES;
  [self updateLayout];
}

- (void)addSubview:(NSView*)view
{
  if (![view isKindOfClass:NSClassFromString(@"NSCustomView")]) {
    [view addObserver:self forKeyPath:@"hidden" options:0 context:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subviewFrameChanged:) name:NSViewFrameDidChangeNotification object:view];
  }
  
  [super addSubview:view];
  
  if (inited) {
    [self updateLayout];
  }
}

- (void)willRemoveSubview:(NSView*)view
{
  if ([view superview] == self && ![view isKindOfClass:NSClassFromString(@"NSCustomView")]) {
    [view removeObserver:self forKeyPath:@"hidden" context:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:view];
  }
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
  if ([keyPath isEqualToString:@"hidden"]) {
    [self updateLayout];
  }
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize
{
  [self updateLayout];
}

- (void)subviewFrameChanged:(id)sender
{
  [self updateLayout];
}

- (void)updateLayout
{
  if (updating) {
    return;
  }
  updating = YES;
  BOOL changed = NO;
  
  float fixedWidth = [self frame].size.width;
  float minSpaceUsed = 0;
  int varHeightCount = 0;
  for (NSView* v in [self subviews]) {
    if (![v isHidden]) {
      float min = [self minimumHeight:v];
      float max = [self maximumHeight:v];
      minSpaceUsed += min;
      if (max > min) {
        varHeightCount++;
      }
    }
  }
  float availableHeight = [self frame].size.height - minSpaceUsed;
  
  float pos = [self frame].size.height;
  for (NSView* v in [self subviews]) {
    if (![v isHidden]) {
      float newHeight;
      float min = [self minimumHeight:v];
      float max = [self maximumHeight:v];
      if (min == max) {
        newHeight = min;
      }
      else {
        newHeight = min + (availableHeight / varHeightCount);
        if (newHeight > max) {
          newHeight = max;
        }
      }
      NSRect newFrame = NSMakeRect(0, pos - newHeight, fixedWidth, newHeight);
      NSRect oldFrame = [v frame];
      if (!NSEqualRects(oldFrame, newFrame)) {
        [v setFrame:newFrame];
        changed = YES;
      }
      pos -= newHeight;
    }
  }
  
  if (changed) {
    [self setNeedsDisplay:YES];
  }
  updating = NO;
}

- (float)minimumHeight:(NSView*)view
{
  if ([view conformsToProtocol:@protocol(ViewSizeLimits)]) {
    return [(id<ViewSizeLimits>)view minimumSize].height;
  }
  return 0;
}

- (float)maximumHeight:(NSView*)view
{
  if ([view conformsToProtocol:@protocol(ViewSizeLimits)]) {
    return [(id<ViewSizeLimits>)view maximumSize].height;
  }
  return FLT_MAX;
}

@end

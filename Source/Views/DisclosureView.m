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

#import "DisclosureView.h"

#define kDefaultTitleHeight 26
#define kDefaultButtonLeft 2
#define kDefaultLabelLeft 20
#define kButtonBottomMargin 5
#define kLabelBottomMargin 2
#define kButtonSize 13
#define kLabelHeight 18


@implementation DisclosureView

- (id)initWithFrame:(NSRect)f
{
  self = [super initWithFrame:f];
  [super setAutoresizesSubviews:NO];
  inited = NO;
  enabled = YES;
  expanded = YES;
  indentContent = NO;
  fixedHeight = YES;
  titleHeight = kDefaultTitleHeight;
  preferredWidth = f.size.width;
  preferredHeight = f.size.height;
  return self;
}

- (void)dealloc
{
  [contentView release];
  [title release];
  [super dealloc];
}

- (void)setAutoresizesSubviews:(BOOL)flag
{
}

- (void)awakeFromNib
{
  if (inited) {
    return;
  }
  inited = YES;
  
  if (!title) {
    title = [[self toolTip] retain];
  }
  
  NSRect cvf = [self makeContentViewFrame];
  contentView = [[[NSView alloc] initWithFrame:cvf] retain];
  [contentView setAutoresizesSubviews:YES];
  for (NSView* v in [NSArray arrayWithArray:[self subviews]]) {
    [v removeFromSuperview];
    [contentView addSubview:v];
  }
  [contentView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
  
  [super setAutoresizesSubviews:YES];
  [self setFrameSize:NSMakeSize(preferredWidth, preferredHeight + titleHeight)];

  if (expanded) {
    [self addSubview:contentView];
  }
  
  NSRect buttonFrame = NSMakeRect(kDefaultButtonLeft, preferredHeight + kButtonBottomMargin,
                                  kButtonSize, kButtonSize);
  disclosureButton = [[NSButton alloc] initWithFrame:buttonFrame];
  [disclosureButton setAutoresizingMask:(NSViewMaxXMargin | NSViewMinYMargin)];
  [disclosureButton setButtonType:NSOnOffButton];
  [disclosureButton setBezelStyle:NSDisclosureBezelStyle];
  [disclosureButton setTitle:@""];
  [disclosureButton setTarget:self];
  [disclosureButton setAction:@selector(toggle:)];
  [disclosureButton setState:(expanded ? NSOnState : NSOffState)];
  [disclosureButton setHidden:!enabled];
  [self addSubview:disclosureButton];
  
  NSRect labelFrame = NSMakeRect(kDefaultLabelLeft, preferredHeight + kLabelBottomMargin,
                                 preferredWidth - (kDefaultLabelLeft + 2), kLabelHeight);
  label = [[NSTextField alloc] initWithFrame:labelFrame];
  [label setAutoresizingMask:(NSViewWidthSizable | NSViewMinYMargin)];
  [label setEditable:NO];
  [label setStringValue:title];
  [label setBordered:NO];
  [label setDrawsBackground:NO];
  [self addSubview:label];
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize
{
  [super resizeSubviewsWithOldSize:oldSize];
  if (expanded) {
    NSRect f = [self frame];
    preferredHeight = f.size.height - titleHeight;
    [contentView setFrame:[self makeContentViewFrame]];
  }
}

- (NSView*)contentView
{
  return contentView;
}

- (BOOL)isEnabled
{
  return enabled;
}

- (void)setEnabled:(BOOL)e
{
  if (enabled != e) {
    enabled = e;
    [disclosureButton setHidden:!e];
  }
}

- (BOOL)isExpanded
{
  return expanded;
}

- (void)setExpanded:(BOOL)e
{
  if (expanded != e) {
    expanded = e;
    [disclosureButton setState:(e ? NSOnState : NSOffState)];
    NSRect f = [self frame];
    
    if (!e) {
      preferredHeight = [contentView frame].size.height;
    }

    float newHeight = e ? (preferredHeight + titleHeight) : titleHeight;
    NSRect r = NSMakeRect(f.origin.x, f.origin.y - (newHeight - f.size.height),
                         f.size.width, newHeight);
    
    if (e) {
      [self setFrame:r];
      [contentView setFrame:[self makeContentViewFrame]];
      [self addSubview:contentView];
    }
    else {
      [contentView removeFromSuperview];
      [self setFrame:r];
    }

    [self setNeedsDisplay:YES];
  }
}

- (BOOL)isIndentContent
{
  return indentContent;
}

- (void)setIndentContent:(BOOL)flag
{
  if (flag != indentContent) {
    indentContent = flag;
    [contentView setFrame:[self makeContentViewFrame]];
  }
}

- (BOOL)fixedHeight
{
  return fixedHeight;
}

- (void)setFixedHeight:(BOOL)f
{
  fixedHeight = f;
}

- (float)preferredHeight
{
  return preferredHeight;
}

- (void)setPreferredHeight:(float)newHeight
{
  if (preferredHeight != newHeight) {
    preferredHeight = newHeight;
    
    if (expanded) {
      [self setFrameSize:NSMakeSize([self frame].size.width, titleHeight + newHeight)];
      [contentView setFrame:[self makeContentViewFrame]];
    }
  }
}

- (NSString*)title
{
  return title;
}

- (void)setTitle:(NSString*)t
{
  if (title != t) {
    [title release];
    title = [t retain];
    [label setStringValue:t];
  }
}

- (void)toggle:(id)sender
{
  if (sender != disclosureButton) {
    [disclosureButton setState:(([disclosureButton state] == NSOnState) ? NSOffState : NSOnState)];
  }
  [self setExpanded:([disclosureButton state] == NSOnState)];
}

- (NSSize)minimumSize
{
  return NSMakeSize(preferredWidth, expanded ? (preferredHeight + titleHeight) : titleHeight);
}

- (NSSize)maximumSize
{
  return expanded ? NSMakeSize(preferredWidth, fixedHeight ? (preferredHeight + titleHeight) : FLT_MAX) : [self minimumSize];
}

- (NSRect)makeContentViewFrame
{
  float x = indentContent ? kDefaultLabelLeft : 0;
  return NSMakeRect(x, 0, [self frame].size.width - x, preferredHeight);
}

@end

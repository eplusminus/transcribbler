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

#import "Transcribbler-Swift.h"

#import "AbbrevsController.h"

#import "DisclosureView.h"
#import "HandyTableView.h"
#import "StackingView.h"


@implementation AbbrevsController

@synthesize document;

- (id)initWithCoder:(NSCoder*)aDecoder
{
  self = [super initWithCoder:aDecoder];
  [NSBundle loadNibNamed:@"AbbrevDrawerView" owner:self];
  return self;
}

- (void)dealloc
{
  [document release];
  [listView release];
  [textView release];
  [disclosureView release];
  [super dealloc];
}

- (void)awakeFromNib
{
  if (drawer && [drawer contentView] != [self view]) {
    NSSize size = [[self view] frame].size;
    [[self view] setAutoresizesSubviews:YES];
    [drawer setContentSize:size];
    [drawer setMinContentSize:size];
    [drawer setContentView:[self view]];
  }
  [disclosureView setFixedHeight:NO];
}

- (void)addAbbrevListDocument:(AbbrevListDocument*)d
{
  if (document == nil) {
    document = [d retain];
    if (![document view]) {
      [NSBundle loadNibNamed:@"AbbrevListView" owner:document];
    }
    listView = [[document view] retain];
    [listView setFrameOrigin:NSMakePoint(0, 0)];
    [listView setFrameSize:[containerView frame].size];
    [listView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
    [containerView addSubview:listView];
    [document tableView].backTabDestination = textView;
    [disclosureView retain];
  }
}

- (IBAction)newAbbreviation:(id)sender
{
  [drawer open];
  [NSApp sendAction:@selector(add:) to:[[document tableView] delegate] from:self];
}

- (NSView*)textView
{
  return textView;
}

- (void)setTextView:(NSView *)v
{
  if (v != textView) {
    [textView release];
    textView = [v retain];
    [document tableView].backTabDestination = textView;
  }
}

- (void)lendViewsTo:(StackingView*)sv
{
  [listView removeFromSuperview];
  [[disclosureView contentView] addSubview:listView];
  [listView setFrame:[[disclosureView contentView] frame]];
  [sv addSubview:disclosureView];
}

- (void)restoreViews
{
  [disclosureView removeFromSuperview];
  [listView removeFromSuperview];
  [containerView addSubview:listView];
  [listView setFrame:NSMakeRect(0, 0, [containerView frame].size.width, [containerView frame].size.height)];
}

//
// informal protocol NSMenuValidation
//

- (BOOL) validateMenuItem:(NSMenuItem*)menuItem
{
  if ([menuItem action] == @selector(newAbbreviation:)) {
    return YES;
  }
  return NO;
}

@end

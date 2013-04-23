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

#import "TransTextWindowController.h"

#import "AbbrevListDocument.h"
#import "AbbrevsController.h"
#import "DisclosureView.h"
#import "HandyTableView.h"
#import "MediaController.h"
#import "StackingView.h"
#import "TransTextView.h"


@implementation TransTextWindowController

@synthesize abbrevsController, mediaController, textView;

- (void)dealloc
{
  [mainContentView release];
  [fullScreenSidebarView release];
  [toolbar release];
  [splitter release];
  [super dealloc];
}

- (void)windowDidLoad
{
  [super windowDidLoad];
  
  [mediaController setNextResponder:[self nextResponder]];
  [abbrevsController setNextResponder:mediaController];
  [self setNextResponder:abbrevsController];

  [abbrevsController setTextView:textView];
  
  [mediaDrawer setDelegate:self];
  [abbrevDrawer setDelegate:self];
  
  fullScreenSidebarWidth = 250;
  toolbarVisibleInFullScreen = NO;
  
  NSRect r0 = NSMakeRect(0, 0, 200, 200);
  NSRect r1 = NSMakeRect(0, 0, 100, 200);
  splitter = [[NSSplitView alloc] initWithFrame:r0];
  [splitter setVertical:YES];
  [splitter setDividerStyle:NSSplitViewDividerStyleThin];
  [splitter setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];

  fullScreenSidebarView = [[NSView alloc] initWithFrame:r1];
  stackingView = [[StackingView alloc] initWithFrame:NSInsetRect(r1, 4, 4)];
  [stackingView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
  [fullScreenSidebarView addSubview:stackingView];
  [splitter addSubview:fullScreenSidebarView];
  
  [mainContentView retain];
  
  [[self document] windowControllerDidLoadNib:self];
}

- (IBAction)toggleMediaDrawer:(id)sender
{
  [self toggleDrawer:mediaDrawer onEdge:NSMinXEdge];
}

- (IBAction)toggleAbbrevDrawer:(id)sender
{
  [self toggleDrawer:abbrevDrawer onEdge:NSMaxXEdge];
}

- (IBAction)toggleRuler:(id)sender
{
  [textView setRulerVisible:![textView isRulerVisible]];
}

//
// protocol NSWindowDelegate
//

- (id)windowWillReturnFieldEditor:(NSWindow*)sender toObject:(id)anObject
{
  return [HandyTableView windowWillReturnFieldEditor:sender toObject:anObject];
}

- (void)windowWillEnterFullScreen:(NSNotification*)notification
{
  toolbar = [[[self window] toolbar] retain];
  toolbarVisibleDefault = [toolbar isVisible];
  [[self window] setToolbar:nil];

  [splitter setFrame: [[[self window] contentView] frame]];
  [mainContentView removeFromSuperview];
  [splitter addSubview:mainContentView];
  [splitter setPosition:fullScreenSidebarWidth ofDividerAtIndex:0];
  [[[self window] contentView] addSubview:splitter];
  
  [mediaController lendViewsTo:stackingView];
  [abbrevsController lendViewsTo:stackingView];
  
  [textView setTextContainerInset:NSMakeSize(100, 0)];  
}

- (void)windowWillExitFullScreen:(NSNotification*)notification
{
  fullScreenSidebarWidth = [fullScreenSidebarView frame].size.width - 40;
  
  NSRect cf = [[[self window] contentView] frame];
  [mainContentView removeFromSuperview];
  [splitter removeFromSuperview];
  [mainContentView setFrame:cf];
  [[[self window] contentView] addSubview:mainContentView];
  
  [mediaController restoreViews];
  [abbrevsController restoreViews];
  
  [textView setTextContainerInset:NSMakeSize(0, 0)];
}

- (void)windowDidExitFullScreen:(NSNotification*)notification
{
  [[self window] setToolbar:toolbar];
  [toolbar setVisible:toolbarVisibleDefault];
  [toolbar release];
  toolbar = nil;
}

//
// protocol NSDrawerDelegate
//

- (void)drawerDidOpen:(NSNotification*)notification
{
  NSDrawer* drawer = [notification object];
  NSRect sf = [[[self window] screen] visibleFrame];
  NSRect df = [[[drawer contentView] window] frame];
  if (!NSContainsRect(sf, df)) {
    [[self window] zoom:nil];
  }
}

//
// informal protocol NSUserInterfaceValidations
//

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)item
{
  SEL a = [item action];
  if (a == @selector(toggleMediaDrawer:)) {
    if ([(NSObject*)item isKindOfClass:[NSMenuItem class]]) {
      [(NSMenuItem*)item setState:[mediaDrawer state]];
    }
    return YES;
  }
  if (a == @selector(toggleAbbrevDrawer:)) {
    if ([(NSObject*)item isKindOfClass:[NSMenuItem class]]) {
      [(NSMenuItem*)item setState:[abbrevDrawer state]];
    }
    return YES;
  }
  if (a == @selector(toggleRuler:)) {
    return YES;
  }
  if (a == @selector(newAbbreviation:)) {
    return YES;
  }
  return NO;
}


//
// informal protocol NSToolbarItemValidation
//

//
// internal
//

- (void)toggleDrawer:(NSDrawer*)drawer onEdge:(NSRectEdge)edge
{
  if ([drawer state] == NSDrawerOpenState) {
    [drawer close];
  }
  else {
    [drawer openOnEdge:edge];
  }
}

@end

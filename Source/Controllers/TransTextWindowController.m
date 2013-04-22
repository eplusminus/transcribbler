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
#import "HandyTableView.h"
#import "MediaController.h"
#import "TransTextView.h"


@implementation TransTextWindowController

@synthesize abbrevsController, mediaController, textView;

- (void)dealloc
{
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

- (BOOL)isMediaDrawerOpen
{
  return ([mediaDrawer state] == NSDrawerOpenState);
}

- (void)setMediaDrawerOpen:(BOOL)open
{
  [self setDrawerState:mediaDrawer open:open];
}

- (BOOL)isAbbrevDrawerOpen
{
  return ([abbrevDrawer state] == NSDrawerOpenState);
}

- (void)setAbbrevDrawerOpen:(BOOL)open
{
  [self setDrawerState:abbrevDrawer open:open];
}

//
// protocol NSWindowDelegate
//

- (id)windowWillReturnFieldEditor:(NSWindow*)sender toObject:(id)anObject
{
  return [HandyTableView windowWillReturnFieldEditor:sender toObject:anObject];
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
// internal
//

- (void)toggleDrawer:(NSDrawer*)drawer onEdge:(NSRectEdge)edge
{
  [self setDrawerState:drawer open:([drawer state] == NSDrawerClosedState)];
}

- (void)setDrawerState:(NSDrawer*)drawer open:(BOOL)open
{
  if (open) {
    [drawer openOnEdge:((drawer == mediaDrawer) ? NSMinXEdge : NSMaxXEdge)];
  }
  else {
    [drawer close];
  }
}

@end

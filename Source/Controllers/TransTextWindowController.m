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
#import "AbbreviationsEditor/AbbreviationsEditor-Swift.h"
#import "HelperViews/HelperViews-Swift.h"

#import "TransTextWindowController.h"

#import "HandyTableView.h"
#import "MediaController.h"


#define kDefaultSidebarWidth 200
#define kMinimumSidebarWidth 126  // width of MiniTimecodeView + insets
#define kSidebarInset 4
#define kSidebarWidthKey @"SidebarWidth"
#define kSidebarHiddenKey @"SidebarHidden"

#define kBothShiftKeys (NSShiftKeyMask | 0x06)


@implementation TransTextWindowController

#define kNSWindowCollectionBehaviorFullScreenPrimary (1 << 7)

@synthesize abbrevsController, mediaController, textView;

- (void)windowDidLoad
{
  [super windowDidLoad];
  
  [[self window] setCollectionBehavior:kNSWindowCollectionBehaviorFullScreenPrimary];
  
  [mediaController setNextResponder:[self nextResponder]];
  [abbrevsController setNextResponder:mediaController];
  [self setNextResponder:abbrevsController];

  [abbrevsController setTextView:textView];
  
  [mediaDrawer setDelegate:self];
  [abbrevDrawer setDelegate:self];
  
  toolbarVisibleInFullScreen = NO;
  
  NSRect r0 = NSMakeRect(0, 0, 200, 200);
  NSRect r1 = NSMakeRect(0, 0, 100, 200);
  splitter = [[NSSplitView alloc] initWithFrame:r0];
  [splitter setVertical:YES];
  [splitter setDividerStyle:NSSplitViewDividerStyleThin];
  [splitter setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
  [splitter setDelegate:self];
  
  fullScreenSidebarView = [[NSView alloc] initWithFrame:r1];
  stackingView = [[StackingView alloc] initWithFrame:NSInsetRect(r1, kSidebarInset, kSidebarInset)];
  [stackingView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
  [fullScreenSidebarView addSubview:stackingView];
  [splitter addSubview:fullScreenSidebarView];
  
  [[self document] windowControllerDidLoadNib:self];
}

- (void)flagsChanged:(NSEvent*)theEvent {
  if (([theEvent modifierFlags] & kBothShiftKeys) == kBothShiftKeys) {
    [[NSApplication sharedApplication] sendAction:@selector(replay:) to:nil from:self];
  }
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

- (void)windowWillEnterFullScreen:(NSNotification*)notification
{
  toolbar = [[self window] toolbar];
  toolbarVisibleDefault = [toolbar isVisible];
  [[self window] setToolbar:nil];

  float scaledWidth = ([TransTextWindowController defaultSidebarWidth] * [[self window] frame].size.width)
    / [[NSScreen mainScreen] frame].size.width;

  [splitter setFrame: [[[self window] contentView] frame]];
  [mainContentView removeFromSuperview];
  [splitter addSubview:mainContentView];
  [splitter setPosition:scaledWidth ofDividerAtIndex:0];
  [fullScreenSidebarView setHidden:[TransTextWindowController defaultSidebarHidden]];
  
  [[[self window] contentView] addSubview:splitter];
  
  [mediaController lendViewsTo:stackingView];
  [abbrevsController lendViewsToStackingView:stackingView];
  
  [textView setTextContainerInset:NSMakeSize(100, 30)];
}

- (void)windowDidEnterFullScreen:(NSNotification *)notification
{
  // set splitter position again in case scaledWidth had a rounding error
  if (![fullScreenSidebarView isHidden]) {
    [splitter setPosition:[TransTextWindowController defaultSidebarWidth] ofDividerAtIndex:0];
  }
}

- (void)windowWillExitFullScreen:(NSNotification*)notification
{
  [TransTextWindowController setDefaultSidebarWidth:[fullScreenSidebarView frame].size.width];
  [TransTextWindowController setDefaultSidebarHidden:[fullScreenSidebarView isHidden]];
  
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
// protocol NSSplitViewDelegate
//

- (BOOL)splitView:(NSSplitView*)splitView canCollapseSubview:(NSView*)subview
{
  return (subview == fullScreenSidebarView);
}

- (CGFloat)splitView:(NSSplitView*)splitView constrainMinCoordinate:(CGFloat)proposedMin
         ofSubviewAt:(NSInteger)dividerIndex
{
  if (dividerIndex == 0) {
    return kMinimumSidebarWidth;
  }
  return proposedMin;
}

- (BOOL)splitView:(NSSplitView*)splitView shouldCollapseSubview:(NSView*)subview
  forDoubleClickOnDividerAtIndex:(NSInteger)dividerIndex
{
  return YES;
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

+ (float)defaultSidebarWidth
{
  float f = [[NSUserDefaults standardUserDefaults] floatForKey:kSidebarWidthKey];
  return (f == 0) ? kDefaultSidebarWidth : ((f < 0) ? 0 : f);
}

+ (void)setDefaultSidebarWidth:(float)width
{
  [[NSUserDefaults standardUserDefaults] setFloat:((width <= 0) ? -1 : width) forKey:kSidebarWidthKey];
}

+ (BOOL)defaultSidebarHidden
{
  return [[NSUserDefaults standardUserDefaults] boolForKey:kSidebarHiddenKey];
}

+ (void)setDefaultSidebarHidden:(BOOL)hidden
{
  [[NSUserDefaults standardUserDefaults] setBool:hidden forKey:kSidebarHiddenKey];
}

@end

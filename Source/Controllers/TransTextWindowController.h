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

#import <Cocoa/Cocoa.h>

@class AbbrevsController;
@class DisclosureView;
@class MediaController;
@class StackingView;
@class TransTextView;


@interface TransTextWindowController : NSWindowController <NSWindowDelegate, NSDrawerDelegate> {
 @private
  IBOutlet MediaController* mediaController;
  IBOutlet AbbrevsController* abbrevsController;
  
  IBOutlet NSView* mainContentView;
	IBOutlet TransTextView* textView;
  IBOutlet NSScrollView* scrollView;
  IBOutlet NSDrawer* mediaDrawer;
  IBOutlet NSDrawer* abbrevDrawer;
  
  BOOL fullScreen;
  NSToolbar* toolbar;
  NSSplitView* splitter;
  NSView* fullScreenSidebarView;
  StackingView* stackingView;
  BOOL toolbarVisibleDefault;
  BOOL toolbarVisibleInFullScreen;
}

@property (readonly) AbbrevsController* abbrevsController;
@property (readonly) MediaController* mediaController;
@property (readonly) TransTextView* textView;

- (IBAction)toggleMediaDrawer:(id)sender;
- (IBAction)toggleAbbrevDrawer:(id)sender;
- (IBAction)toggleRuler:(id)sender;

- (BOOL)isMediaDrawerOpen;
- (void)setMediaDrawerOpen:(BOOL)open;
- (BOOL)isAbbrevDrawerOpen;
- (void)setAbbrevDrawerOpen:(BOOL)open;

@end

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

#import "ViewSizeLimits.h"

#import <Cocoa/Cocoa.h>

@interface DisclosureView : NSView <ViewSizeLimits> {
 @private
  IBOutlet NSButton* disclosureButton;
  IBOutlet NSTextField* label;

  BOOL inited;
  NSView* contentView;
  NSString* title;
  BOOL enabled;
  BOOL expanded;
  BOOL fixedHeight;
  BOOL indentContent;
  float titleHeight;
  float preferredHeight;
  float preferredWidth;
}

- (NSView*)contentView;

- (BOOL)isEnabled;
- (void)setEnabled:(BOOL)enabled;

- (BOOL)isExpanded;
- (void)setExpanded:(BOOL)expanded;

- (BOOL)isIndentContent;
- (void)setIndentContent:(BOOL)indentContent;

- (float)preferredHeight;
- (void)setPreferredHeight:(float)expandedHeight;

- (BOOL)fixedHeight;
- (void)setFixedHeight:(BOOL)fixedHeight;

- (NSString*)title;
- (void)setTitle:(NSString*)title;

- (IBAction)toggle:(id)sender;

@end
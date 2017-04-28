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

@class QuickTableTextView;
@protocol HandyTableViewDelegate;


@interface HandyTableView : NSTableView {
 @private
  IBOutlet NSView* backTabDestination;
  IBOutlet NSView* forwardTabDestination;
  
  NSInteger clickedCol;
  NSInteger clickedRow;
  BOOL editing;
  BOOL tabWrapsForward;
  BOOL tabWrapsBackward;
  
  QuickTableTextView* fieldEditor;
}

@property (retain) NSView* backTabDestination;
@property (retain) NSView* forwardTabDestination;

+ (id)windowWillReturnFieldEditor:(NSWindow*)sender toObject:(id)anObject;
- (id<HandyTableViewDelegate>)handyDelegate;

@end


@protocol HandyTableViewDelegate

- (BOOL)tableView:(HandyTableView*)view canDeleteEmptyRow:(NSUInteger)row;
- (BOOL)tableView:(HandyTableView*)view clickedBelowLastRowAt:(NSPoint)point;

@end
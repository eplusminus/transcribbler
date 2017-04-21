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

#import "HandyTableView.h"


@interface QuickTableTextView : NSTextView {
@private
  HandyTableView *tableView;
	NSUInteger movedVerticallyAtCharPos;
	float movedVerticallyAtPixelPos;
}

- (id)initWithTableView:(HandyTableView*)owner;

@end


@implementation HandyTableView

@synthesize backTabDestination, forwardTabDestination;

- (id)initWithCoder:(NSCoder*)aDecoder
{
  self = [super initWithCoder:aDecoder];
  fieldEditor = [[[QuickTableTextView alloc] initWithTableView:self] retain];
  return self;
}

- (id)initWithFrame:(NSRect)frameRect
{
  self = [super initWithFrame:frameRect];
  fieldEditor = [[[QuickTableTextView alloc] initWithTableView:self] retain];
  return self;
}

- (void)dealloc
{
  [fieldEditor release];
  self.backTabDestination = nil;
  self.forwardTabDestination = nil;
  [super dealloc];
}

- (id<HandyTableViewDelegate>)handyDelegate
{
  id d = [self delegate];
  return ([d conformsToProtocol:@protocol(HandyTableViewDelegate)]) ? d : nil;
}

//
// NSTableView
//

- (void)textDidEndEditing:(NSNotification*)notification
{
  editing = NO;
  [super textDidEndEditing:notification];
}

//
// to be used from a NSWindowDelegate implementation
//

+ (id)windowWillReturnFieldEditor:(NSWindow*)sender toObject:(id)anObject
{
  if ([anObject isKindOfClass:[HandyTableView class]]) {
		return ((HandyTableView*)anObject)->fieldEditor;
	}
	return nil;
}

//
// NSResponder
//

- (void)mouseDown:(NSEvent*)event
{
	NSPoint loc;
	NSInteger col, row;
  
  clickedRow = clickedCol = -1;
  if ([event clickCount] > 1 && editing) {
    NSTextView *field = (NSTextView*)[self currentEditor];
    [field mouseDown:event];
    return;
  }
  if ([event modifierFlags] & (NSEventModifierFlagShift | NSEventModifierFlagCommand)) {
    [super mouseDown:event];
  }
  else {
    loc = [self convertPoint:[event locationInWindow] fromView:nil];
    col = [self columnAtPoint:loc];
    row = [self rowAtPoint:loc];
    if (row >= 0) {
      if (([self selectedRow] != row) || ([self editedColumn] != col)) {
        [self validateEditing];
        [self abortEditing];
        [self deselectAll:self];
        [self selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
        clickedRow = row;
        clickedCol = col;
      }
    }
    else {
      if (![[self handyDelegate] tableView:self clickedBelowLastRowAt:loc]) {
        [super mouseDown:event];
      }
    }
  }
}

- (void)mouseDragged:(NSEvent *)event
{
  NSPoint loc;
  NSInteger col, row, rowStart, rowEnd;
  
  loc = [self convertPoint:[event locationInWindow] fromView:nil];
  col = [self columnAtPoint:loc];
  row = [self rowAtPoint:loc];
  
  if (row < clickedRow) {
    rowStart = row;
    rowEnd = clickedRow;
  }
  else {
    rowStart = clickedRow;
    rowEnd = row;
  }
  [self scrollRowToVisible:row];
  [self selectRowIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(rowStart, rowEnd - rowStart + 1)]
    byExtendingSelection:NO];
}

- (void)mouseUp:(NSEvent*)event
{
  NSPoint loc;
	NSInteger col, row;
	
  if (([event modifierFlags] & (NSEventModifierFlagShift | NSEventModifierFlagCommand)) == 0) {
    loc = [self convertPoint:[event locationInWindow] fromView:nil];
    col = [self columnAtPoint:loc];
    row = [self rowAtPoint:loc];
    if (row >= 0) {
      if ([[self selectedRowIndexes] count] == 1 && clickedRow == row && clickedCol == col) {
        [self editColumn:col row:row withEvent:nil select:NO];
        NSTextView *field = (NSTextView*)[self currentEditor];
        NSPoint fieldLoc = [field convertPoint:[event locationInWindow] fromView:nil];
        NSUInteger pos = [field characterIndexForInsertionAtPoint:fieldLoc];
        [field setSelectedRange:NSMakeRange(pos, 0)];
        editing = YES;
        return;
      }
    }
  }
  [super mouseUp:event];
}

- (void)scrollWheel:(NSEvent*)theEvent
{
  [super scrollWheel:theEvent];
}

@end

//
// Specialized text view used as a field editor for this table
//

@implementation QuickTableTextView

- (id)initWithTableView:(HandyTableView*)owner
{
  self = [super init];
  tableView = [owner retain];
  return self;
}

- (void)dealloc
{
  [tableView release];
  [super dealloc];
}

//
//	NSTextView
//

- (void)setSelectedRange:(NSRange)r affinity:(NSSelectionAffinity)a
          stillSelecting:(BOOL)flag
{
	[super setSelectedRange:r affinity:a stillSelecting:flag];
	movedVerticallyAtCharPos = NSNotFound;
}

//
//	NSResponder
//

- (void)keyDown:(NSEvent*)event
{
  unichar ch = [[event characters] characterAtIndex:0];
  if (ch == NSTabCharacter) {
    NSInteger row = [tableView editedRow];
    NSInteger col = [tableView editedColumn] + 1;
    if (col == [tableView numberOfColumns]) {
      if (tableView.forwardTabDestination) {
        [[tableView window] makeFirstResponder:tableView.forwardTabDestination];
      }
      else {
        if (row == ([tableView numberOfRows] - 1)) {
          [self insertNewline:nil];
        }
        else {
          [self selectRow:(row+1)];
          [tableView editColumn:0 row:(row+1) withEvent:nil select:NO];
        }
      }
    }
    else {
      [tableView editColumn:col row:row withEvent:nil select:NO];
    }
  }
  else if (ch == NSBackTabCharacter) {
    NSInteger row = [tableView editedRow];
    NSInteger col = [tableView editedColumn] - 1;
    if (col < 0) {
      if (tableView.backTabDestination) {
        [[tableView window] makeFirstResponder:tableView.backTabDestination];
      }
      else {
        if (row > 0) {
          [self selectRow:(row-1)];
          [tableView editColumn:([tableView numberOfColumns]-1) row:(row - 1) withEvent:nil select:NO];
        }
      }
    }
    else {
      [tableView editColumn:col row:row withEvent:nil select:NO];
    }
  }
  else {
    [super keyDown:event];
  }
}

- (void)deleteBackward:(id)sender
{
	NSRange r;
	NSInteger row, col;
  NSText *editor;
  
	r = [self selectedRange];
	if ((r.location > 0) || (r.length > 0) || ([[self string] length] > 0)) {
		[super deleteBackward:sender];
		return;
	}
	row = [tableView editedRow];
	col = [tableView editedColumn];
	if (col == 0) {
    if (row > 0) {
      [tableView validateEditing];
      [tableView abortEditing];
      if ([[tableView handyDelegate] tableView:tableView canDeleteEmptyRow:row]) {
        [[self window] makeFirstResponder:tableView];
        [self selectRow:row];
        [[NSApplication sharedApplication] sendAction:@selector(delete:) to:[tableView delegate] from:self];
      }
      [self selectRow:(row - 1)];
      [tableView editColumn:([tableView numberOfColumns] - 1) row:(row - 1)
                  withEvent:nil select:NO];
      editor = [tableView currentEditor];
      [editor setSelectedRange:NSMakeRange([[editor string] length], 0)];
      
      return;
    }
  }
	[self moveLeft:sender];
}

- (void)moveLeft:(id)sender
{
	NSRange r;
	NSInteger row, col;
	NSText* editor;
	
	r = [self selectedRange];
	if ((r.location > 0) || (r.length > 0)) {
		[super moveLeft:sender];
		return;
	}
	row = [tableView editedRow];
	col = [tableView editedColumn];
	if (col == 0) {
		if (row == 0) {
			return;
		}
		[tableView deselectAll:self];
    [self selectRow:(row-1)];
		[tableView editColumn:([tableView numberOfColumns] - 1) row:row - 1 withEvent:nil
                   select:NO];
	}
	else {
		[tableView deselectAll:self];
    [self selectRow:row];
		[tableView editColumn:(col - 1) row:row withEvent:nil select:NO];
	}
	editor = [tableView currentEditor];
	[editor setSelectedRange:NSMakeRange([[editor string] length], 0)];
	movedVerticallyAtCharPos = NSNotFound;
}

- (void)moveRight:(id)sender
{
	NSRange r;
	NSInteger row, col;
	NSText* editor;
	
	r = [self selectedRange];
	if ((r.location < [[self string] length]) || (r.length > 0)) {
		[super moveRight:sender];
		return;
	}
	row = [tableView editedRow];
	col = [tableView editedColumn] + 1;
	if (col == [tableView numberOfColumns]) {
		if (row == ([tableView numberOfRows] - 1)) {
			return;
		}
		[tableView deselectAll:self];
    [self selectRow:(row + 1)];
		[tableView editColumn:0 row:(row + 1) withEvent:nil select:NO];
	}
	else {
		[tableView deselectAll:self];
    [self selectRow:row];
		[tableView editColumn:col row:row withEvent:nil select:NO];
	}
	editor = [tableView currentEditor];
	[editor setSelectedRange:NSMakeRange(0, 0)];
	movedVerticallyAtCharPos = NSNotFound;
}

- (void)moveUp:(id)sender
{
	NSInteger row;
  
	row = [tableView editedRow];
	if (row == 0) {
		return;
	}
	[self moveVerticallyToRow:(row - 1)];
}

- (void)moveDown:(id)sender
{
	NSInteger row;
	
	row = [tableView editedRow];
	if (row == ([tableView numberOfRows] - 1)) {
		return;
	}
	[self moveVerticallyToRow:(row + 1)];
}

- (void)insertNewline:(id)sender
{
  [[self window] makeFirstResponder:tableView];
  [[NSApplication sharedApplication] sendAction:@selector(add:) to:nil from:self];
}

//
// internal use
//

- (float)getSelectionPixelPos
{
	NSRange r = [[self layoutManager] glyphRangeForCharacterRange:[self selectedRange]
                                           actualCharacterRange:nil];
	NSRect bounds = [[self layoutManager] boundingRectForGlyphRange:r
                                                  inTextContainer:[self textContainer]];
	return bounds.origin.x;
}

- (void)selectRow:(NSInteger)row
{
  [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
}

- (void)setSelectionPixelPos:(float)pos
{
  NSUInteger p = [self characterIndexForInsertionAtPoint:NSMakePoint(pos, 1)];
  [self setSelectedRange:NSMakeRange(p, 0)];
}

- (void)moveVerticallyToRow:(NSInteger)row
{
	NSInteger col;
  float pos;
	NSRange r;
  
	col = [tableView editedColumn];
	r = [self selectedRange];
	if ((r.length == 0) && (r.location == movedVerticallyAtCharPos)) {
		pos = movedVerticallyAtPixelPos;
	}
	else {
		pos = [self getSelectionPixelPos];
		movedVerticallyAtPixelPos = pos;
	}
	[tableView deselectAll:self];
	[tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
	[tableView editColumn:col row:row withEvent:nil select:NO];
	[self setSelectionPixelPos:pos];
	r = [self selectedRange];
	movedVerticallyAtCharPos = r.location;
}

@end

/*
 
 Transcriptacular, a Mac OS X text editor for audio/video transcription
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

#import "QuickTableTextView.h"


@implementation QuickTableTextView

@synthesize document, tableView;

- (void) dealloc
{
    document = nil;
    tableView = nil;
    [super dealloc];
}


- (unsigned) getSelectionPixelPos
{
	NSRange r = [[self layoutManager] glyphRangeForCharacterRange:[self selectedRange]
                                             actualCharacterRange:nil];
	NSRect bounds = [[self layoutManager] boundingRectForGlyphRange:r
                                             inTextContainer:[self textContainer]];
	return bounds.origin.x;
}

- (void) selectRow:(int)row
{
    [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
}

- (void) setSelectionPixelPos:(unsigned)pos
{
    NSUInteger p = [self characterIndexForInsertionAtPoint:NSMakePoint(pos, 1)];
    [self setSelectedRange:NSMakeRange(p, 0)];
}

- (void) moveVerticallyToRow:(unsigned)row
{
	unsigned col, pos;
	NSRange r;
    
	col = [tableView editedColumn];
	r = [self selectedRange];
	if ((r.length == 0) && (r.location == _movedVerticallyAtCharPos)) {
		pos = _movedVerticallyAtPixelPos;
	}
	else {
		pos = [self getSelectionPixelPos];
		_movedVerticallyAtPixelPos = pos;
	}
	[tableView deselectAll:self];
	[tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
	[tableView editColumn:col row:row withEvent:nil select:NO];
	[self setSelectionPixelPos:pos];
	r = [self selectedRange];
	_movedVerticallyAtCharPos = r.location;
}

//
//	NSTextView methods
//

- (void) setSelectedRange:(NSRange)r affinity:(NSSelectionAffinity)a
           stillSelecting:(BOOL)flag
{
	[super setSelectedRange:r affinity:a stillSelecting:flag];
	_movedVerticallyAtCharPos = -1;
}

//
//	NSResponder methods
//

- (void) keyDown:(NSEvent*)event
{
    if ([[event characters] isEqualToString:@"\t"]) {
        int row = [tableView editedRow];
        int col = [tableView editedColumn] + 1;
        if (col == [tableView numberOfColumns]) {
            if (row == ([tableView numberOfRows] - 1)) {
                [self insertNewline:nil];
            }
            else {
                [self selectRow:(row+1)];
                [tableView editColumn:0 row:(row+1) withEvent:nil select:NO];
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

- (void) deleteBackward:(id)sender
{
	NSRange r;
	unsigned row, col;
    NSText *editor;
    
	r = [self selectedRange];
	if ((r.location > 0) || (r.length > 0) || ([[self string] length] > 0)) {
		[super deleteBackward:sender];
		return;
	}
	row = [tableView editedRow];
	col = [tableView editedColumn];
	if (col == 0) {
		if (YES) {
            [tableView abortEditing];
            [[self window] makeFirstResponder:tableView];
            [self selectRow:row];
            [[NSApplication sharedApplication] sendAction:@selector(delete:) to:nil from:self];
			[self selectRow:(row-1)];
			[tableView editColumn:([tableView numberOfColumns] - 1) row:(row - 1)
                         withEvent:nil select:NO];
			editor = [tableView currentEditor];
			[editor setSelectedRange:NSMakeRange([[editor string] length], 0)];
		}
		return;
	}
	[self moveLeft:sender];
}

- (void) moveLeft:(id)sender
{
	NSRange r;
	int row, col;
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
	_movedVerticallyAtCharPos = -1;
}

- (void) moveRight:(id)sender
{
	NSRange r;
	int row, col;
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
	_movedVerticallyAtCharPos = -1;
}

- (void) moveUp:(id)sender
{
	unsigned row;
    
	row = [tableView editedRow];
	if (row == 0) {
		return;
	}
	[self moveVerticallyToRow:(row - 1)];
}

- (void) moveDown:(id)sender
{
	unsigned row;
	
	row = [tableView editedRow];
	if (row == ([tableView numberOfRows] - 1)) {
		return;
	}
	[self moveVerticallyToRow:(row + 1)];
}

- (void) insertNewline:(id)sender
{
    [[self window] makeFirstResponder:tableView];
    [[NSApplication sharedApplication] sendAction:@selector(add:) to:nil from:self];
}

@end

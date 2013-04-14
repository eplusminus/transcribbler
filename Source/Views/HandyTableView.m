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

#import "HandyTableView.h"


@implementation HandyTableView

- (void) mouseUp:(NSEvent*)event
{
    NSPoint loc;
	int col, row;
	
    if (([event modifierFlags] & (NSShiftKeyMask | NSCommandKeyMask)) == 0) {
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

- (void) scrollWheel:(NSEvent *)theEvent
{
    [super scrollWheel:theEvent];
}

- (void) mouseDown:(NSEvent*)event
{
	NSPoint loc;
	int col, row;
    
    if ([event clickCount] > 1 && editing) {
        NSTextView *field = (NSTextView*)[self currentEditor];
        [field mouseDown:event];
        return;
    }
    if ([event modifierFlags] & (NSShiftKeyMask | NSCommandKeyMask)) {
        [super mouseDown:event];
    }
    else {
        loc = [self convertPoint:[event locationInWindow] fromView:nil];
        col = [self columnAtPoint:loc];
        row = [self rowAtPoint:loc];
        if (row >= 0) {
            if ([self selectedRow] != row) {
                [self validateEditing];
                [self abortEditing];
                [self deselectAll:self];
                [self selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
                clickedRow = row;
                clickedCol = col;
            }
        }
        else {
            [super mouseDown:event];
        }
    }
}

- (void) mouseDragged:(NSEvent *)event
{
    NSPoint loc;
    int col, row, rowStart, rowEnd;
    
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

- (void) textDidEndEditing:(NSNotification *)notification
{
    editing = NO;
    [super textDidEndEditing:notification];
}

@end

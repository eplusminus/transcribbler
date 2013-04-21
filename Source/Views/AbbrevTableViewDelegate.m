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

#import "AbbrevTableViewDelegate.h"

#import "AbbrevArrayController.h"
#import "AbbrevListDocument.h"
#import "AbbrevResolver.h"
#import "AbbrevResolverImpl.h"
#import "AppDelegate.h"
#import "HandyTableView.h"


@implementation AbbrevTableViewDelegate

- (void)dealloc
{
  [resolver release];
  [super dealloc];
}

- (void)awakeFromNib
{
  [self setNextResponder:[view nextResponder]];
  [view setNextResponder:self];
  
  resolver = [[table document] abbrevResolver];
}

- (IBAction)delete:(id)sender
{
  [table delete:self];
}

- (IBAction)cut:(id)sender
{
  [table copy:self];
  [table delete:self];
}

- (IBAction)copy:(id)sender
{
  [table copy:self];
}

- (IBAction)paste:(id)sender
{
  [table paste:self];
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
  AbbrevEntry *a = [[table arrangedObjects] objectAtIndex:rowIndex];
  if (a != nil) {
    NSTextFieldCell *cell = aCell;
    if ([[aTableColumn identifier] isEqualToString:@"abbreviation"] && [resolver hasDuplicateAbbreviation:a]) {
      [cell setBackgroundColor:[NSColor yellowColor]];
      [cell setDrawsBackground:YES];
    }
    else {
      [cell setBackgroundColor:[NSColor textBackgroundColor]];
      [cell setDrawsBackground:NO];
    }
  }
}

- (IBAction)newAbbreviation:(id)sender
{
  [self add:sender];
}

- (IBAction)add:(id)sender
{
  NSInteger row = [view selectedRow];
  if (row < 0) {
    row = [view numberOfRows];
  }
  else {
    AbbrevEntry* e = [[table arrangedObjects] objectAtIndex:row];
    if ([e isEmpty]) {
      [view editColumn:0 row:row withEvent:nil select:NO];
      return;
    }
    row++;
  }
  [table insertObject:[table newEntry] atArrangedObjectIndex:row];
  [view selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
  [view editColumn:0 row:row withEvent:nil select:NO];
}

- (void)keyDown:(NSEvent*)e
{
	unichar ch = [[e characters] characterAtIndex:0];
    
	if (ch == NSDeleteCharacter || ch == NSDeleteFunctionKey) {
		[self delete:self];
	}
	else
	{
		[super keyDown:e];
	}
}

- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)item
{
  SEL theAction = [item action];
  
  if (theAction == @selector(copy:) || theAction == @selector(cut:) || theAction == @selector(delete:)) {
    return ([table selectionIndex] != NSNotFound) ? YES : NO;
  }
  
  if (theAction == @selector(paste:)) {
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    if ([pb dataForType:AbbreviationsPasteboardType] != nil ||
      [pb dataForType:NSStringPboardType] != nil) {
      return YES;
    }
    return NO;
  }
  
  return NO;
}

//
// HandyTableView delegate
//

- (BOOL)tableView:(HandyTableView*)view canDeleteEmptyRow:(NSUInteger)row
{
  AbbrevEntry* e = [[table arrangedObjects] objectAtIndex:row];
  return [e isEmpty];
}

@end

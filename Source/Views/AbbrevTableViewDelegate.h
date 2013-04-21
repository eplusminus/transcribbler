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

#import <Foundation/Foundation.h>

@protocol AbbrevResolver;
@class AbbrevArrayController;


@interface AbbrevTableViewDelegate : NSResponder <NSTableViewDelegate, HandyTableViewDelegate> {
 @private
  IBOutlet AbbrevArrayController* table;
  IBOutlet NSTableView* view;

  NSObject<AbbrevResolver>* resolver;
}

- (IBAction)add:(id)sender;
- (IBAction)delete:(id)sender;
- (IBAction)cut:(id)sender;
- (IBAction)copy:(id)sender;
- (IBAction)paste:(id)sender;

- (void)tableView:(NSTableView*)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn*)aTableColumn row:(NSInteger)rowIndex;
- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)item;

@end

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

#import "AppDelegate.h"
#import "TransTextDocument.h"


@implementation TransTextDocument

- (NSString*) windowNibName
{
    return @"TransTextDocument";
}

- (void) windowControllerDidLoadNib:(NSWindowController*)windowController
{
    [super windowControllerDidLoadNib:windowController];

	 if (loadedText) {
        [[textView textStorage] replaceCharactersInRange:NSMakeRange(0, [[textView string] length]) withAttributedString:loadedText];
        [loadedText release];
    }
}

- (NSRect) windowWillUseStandardFrame:(NSWindow*)window defaultFrame:(NSRect)newFrame
{
    AppDelegate* ad = [NSApp delegate];
    return [ad windowZoomRect];
}
	
- (BOOL) readFromFileWrapper:(NSFileWrapper*)file ofType:(NSString*)type error:(NSError**)error
{
	loadedText = [[NSAttributedString alloc] initWithRTF:[file regularFileContents] documentAttributes:nil];

	if (textView) {                                                         
        [[textView textStorage] replaceCharactersInRange:NSMakeRange(0, [[textView string] length]) withAttributedString:loadedText];
        [loadedText release];
	}
    
	return YES;
}

- (NSFileWrapper*) fileWrapperOfType:(NSString*)type error:(NSError**)error
{
	NSFileWrapper* file = [[NSFileWrapper alloc] initRegularFileWithContents:[[textView textStorage] RTFFromRange:NSMakeRange(0, [[textView string] length]) documentAttributes:nil]];
	
    return [file autorelease];
}

@end

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

#import "TransTextDocument.h"

#import "AbbrevListDocument.h"
#import "AbbrevResolver.h"
#import "AbbrevResolverImpl.h"
#import "AbbrevsController.h"
#import "AppDelegate.h"
#import "TransTextWindowController.h"
#import "TransTextView.h"


@implementation TransTextDocument

@synthesize abbrevListDocument, abbrevResolver;

- (id)init
{
  self = [super init];
  abbrevListDocument = [[[AbbrevListDocument alloc] init] retain];
  abbrevResolver = [[[AbbrevResolverImpl alloc] init] retain];
  [abbrevResolver addedDocument:abbrevListDocument];
  abbrevListDocument.abbrevResolver = abbrevResolver;
  return self;
}

- (void)dealloc
{
  [windowController release];
  [abbrevListDocument release];
  [abbrevResolver release];
  [super dealloc];
}

- (void)makeWindowControllers
{
  windowController = [[[TransTextWindowController alloc] initWithWindowNibName:@"TransTextDocument"] retain];
  [self addWindowController:windowController];
}

- (void)windowControllerDidLoadNib:(NSWindowController*)w
{
  [super windowControllerDidLoadNib:w];

  textStorage = [[windowController textView] textStorage];
  if (loadedText) {
    [textStorage replaceCharactersInRange:NSMakeRange(0, [textStorage length]) withAttributedString:loadedText];
    [loadedText release];
  }
  
  [[windowController abbrevsController] addAbbrevListDocument:abbrevListDocument];
  [windowController textView].abbrevResolver = abbrevResolver;
}
	
- (BOOL)readFromFileWrapper:(NSFileWrapper*)file ofType:(NSString*)type error:(NSError**)error
{
	loadedText = [[NSAttributedString alloc] initWithRTF:[file regularFileContents] documentAttributes:nil];

	if (textStorage) {
    [textStorage replaceCharactersInRange:NSMakeRange(0, [textStorage length]) withAttributedString:loadedText];
    [loadedText release];
	}
    
	return YES;
}

- (NSFileWrapper*)fileWrapperOfType:(NSString*)type error:(NSError**)error
{
	NSFileWrapper* file = [[NSFileWrapper alloc] initRegularFileWithContents:[[textView textStorage] RTFFromRange:NSMakeRange(0, [[textView string] length]) documentAttributes:nil]];
	
  return [file autorelease];
}

@end

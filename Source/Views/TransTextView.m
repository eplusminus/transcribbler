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

#import "TransTextView.h"

#import "AbbrevArrayController.h"
#import "AbbrevParser.h"
#import "AbbrevResolver.h"
#import "AppDelegate.h"
#import "TransTextDocument.h"


@implementation TransTextView

@synthesize abbrevResolver;

- (void)dealloc
{
  self.abbrevResolver = nil;
  [super dealloc];
}

- (void)awakeFromNib
{
  [self setRulerVisible:YES];
}

- (void)keyDown:(NSEvent*)theEvent {
	
  NSString *chars = [theEvent characters];
  if ([chars length] == 1) {
    unichar ch = [chars characterAtIndex:0];
    if ([AbbrevParser isWordTerminatorChar:ch]) {
      NSRange r = [self selectedRange];
      if (r.length == 0) {
        int pos = r.location;
        NSString* currentText = [[self textStorage] string];
        NSString* lastWord = [self findLastWordIn: currentText fromPos: pos];
        if ([lastWord length] > 0) {
          NSString* expansion = [AbbrevParser expandAbbreviation:lastWord withResolver:abbrevResolver];
          if (expansion) {
            [[[self textStorage] mutableString]
                replaceCharactersInRange: NSMakeRange(pos - [lastWord length], [lastWord length])
                withString: expansion];
            [self setNeedsDisplayInRect:[[[self enclosingScrollView] contentView] visibleRect]];
          }
        }
      }
    }
    if ((ch == 13) && [[[NSUserDefaults standardUserDefaults] objectForKey:@"autoTimestamp"] boolValue] == YES) {
      [[NSNotificationCenter defaultCenter] postNotificationName:@"automaticTimestamp" object:self];
    }
  }
  
	[self interpretKeyEvents:[NSArray arrayWithObject:theEvent]];
}

- (NSString*)findLastWordIn:(NSString*)text fromPos: (int)pos {
    int start;
	for (start = pos - 1; start >= 0; start--) {
		unichar ch = [text characterAtIndex:start];
    if ([AbbrevParser isWordBoundaryChar:ch]) {
      // The following test is meant to keep us from expanding things like the
      // "s" in "that's"; the apostrophe counts as a boundary character for
      // terminating words (so the "that" could be expanded), and it counts as one
      // if it's preceded by another terminator (e.g. a space), but not if it's
      // inside an existing word.
      if (ch == '\'') {
        if (start > 0) {
          if (![AbbrevParser isWordBoundaryChar:[text characterAtIndex:(start - 1)]]) {
            continue;
          }
        }
      }
      break;
		}
	}
  return [text substringWithRange: NSMakeRange(start + 1, pos - (start + 1))];
}

@end

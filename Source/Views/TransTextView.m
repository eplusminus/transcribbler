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

#import "Transcribbler-Swift.h"

#import "TransTextView.h"

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
  AbbrevParser* ap = [AbbrevParser sharedInstance];
  if ([chars length] == 1) {
    unichar ch = [chars characterAtIndex:0];
    if ([ap isWordTerminator:ch]) {
      NSRange r = [self selectedRange];
      if (r.length == 0) {
        int pos = r.location;
        NSString* currentText = [[self textStorage] string];
        NSString* lastWord = [ap findPossibleAbbreviationInString:currentText beforePos:pos];
        if ([lastWord length] > 0) {
          NSString* rawExpansion = [abbrevResolver getExpansion:lastWord];
          if (rawExpansion) {
            NSString* expansion = [ap renderExpansion:rawExpansion abbreviation:lastWord];
            [[[self textStorage] mutableString]
                replaceCharactersInRange: NSMakeRange(pos - [lastWord length], [lastWord length])
                withString: expansion];
            [self setNeedsDisplayInRect:[[[self enclosingScrollView] contentView] visibleRect]];
          }
        }
      }
    }
  }
  
	[self interpretKeyEvents:[NSArray arrayWithObject:theEvent]];
}

@end

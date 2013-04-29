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

#import "AbbrevParser.h"

static AbbrevParser* sAbbrevParser = nil;


@implementation AbbrevParser

+ (AbbrevParser*)sharedInstance
{
  if (!sAbbrevParser) {
    sAbbrevParser = [[AbbrevParser alloc] init];
  }
  return sAbbrevParser;
}

- (id)init
{
  self = [super init];
  wordTerminators = [[NSCharacterSet characterSetWithCharactersInString:
                      @" \r\n\t,.-!?'\""] retain];
  nonTerminatorsInsideWord = [[NSCharacterSet characterSetWithCharactersInString:
                               @"'"] retain];
  return self;
}

- (void)dealloc
{
  [wordTerminators release];
  [nonTerminatorsInsideWord release];
  [super dealloc];
}

- (BOOL)isWordTerminator:(unichar)ch
{
  return [wordTerminators characterIsMember:ch];
}

- (NSString*)findPossibleAbbreviationInString:(NSString*)string beforePos:(NSUInteger)pos
{
  if (pos == 0) {
    return nil;
  }
  NSUInteger start = pos;
  do {
    --start;
		unichar ch = [string characterAtIndex:start];
    if ([wordTerminators characterIsMember:ch]) {
      // The following test is meant to keep us from expanding things like the
      // "s" in "that's"; the apostrophe counts as a boundary character for
      // terminating words (so the "that" could be expanded), and it counts as one
      // if it's preceded by another terminator (e.g. a space), but not if it's
      // inside an existing word.
      if ([nonTerminatorsInsideWord characterIsMember:ch]) {
        if (start > 0) {
          if (![wordTerminators characterIsMember:[string characterAtIndex:(start - 1)]]) {
            continue;
          }
        }
      }
      break;
		}
	} while (start > 0);
  return [string substringWithRange: NSMakeRange(start + 1, pos - (start + 1))];
}

- (NSString*)expandAbbreviation:(NSString*)abbrev withResolver:(id<AbbrevResolver>)resolver
{
    NSString *expansion = [resolver getExpansion:abbrev];
    if (expansion) {
        if (![abbrev isEqualToString:[abbrev lowercaseString]]) {
            // If the whole short form is uppercase, return all uppercase
            if (([abbrev length] > 1) &&
                ([abbrev isEqualToString:[abbrev uppercaseString]])) {
                return [expansion uppercaseString];
            }
            // If the first letter is uppercase, return first letter uppercase
            NSString *first = [abbrev substringToIndex:1];
            if ([first isEqualToString:[first uppercaseString]]) {
                first = [[expansion substringToIndex:1] uppercaseString];
                return [NSString stringWithFormat:@"%@%@", first,
                        [expansion substringFromIndex:1]];
            }
        }
        return expansion;
    }
    return NULL;
}

@end

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

#import "AbbrevParser.h"


@implementation AbbrevParser

+ (BOOL) isWordTerminatorChar:(unichar)ch
{
	return (ch == ' ') || (ch == '\r') || (ch == '\n') || (ch == '\t')
    || (ch == ',') || (ch == '.') || (ch == '-') || (ch == '!')
    || (ch == '?') || (ch == '\'') || (ch == '"');
}

+ (BOOL) isWordBoundaryChar:(unichar)ch
{
	return (ch == ' ') || (ch == '\r') || (ch == '\n') || (ch == '\t')
    || (ch == ',') || (ch == '.') || (ch == '-') || (ch == '!')
    || (ch == '?') || (ch == '\'') || (ch == '"');
}

+ (BOOL) isWordBoundaryCharInsideWord:(unichar)ch
{
	return (ch == ' ') || (ch == '\r') || (ch == '\n') || (ch == '\t')
    || (ch == ',') || (ch == '.') || (ch == '-') || (ch == '!')
    || (ch == '?');
}

+ (NSString*) expandAbbreviation:(NSString*)abbrev withResolver:(id<AbbrevResolver>)resolver
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

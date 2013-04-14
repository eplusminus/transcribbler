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

#import "AbbrevEntry.h"
#import "AbbrevBase.h"


@implementation AbbrevEntry

@synthesize variants;

- (void) dealloc
{
    self.variants = nil;
    [super dealloc];
}

- (NSString*) expansionDesc
{
    if (self.variants == nil) {
        return self.expansion;
    }
    
    NSMutableString *s = [NSMutableString stringWithCapacity:100];
    if (self.expansion != nil) {
        [s appendString:self.expansion];
    }
    if (self.variants != nil && [self.variants count] > 0) {
        [s appendString:@"~"];
        for (AbbrevBase *v in self.variants) {
            if (v.abbreviation != nil) {
                [s appendString:v.abbreviation];
            }
            if (![v.expansion isEqualToString:v.abbreviation]) {
                [s appendString:@"="];
                [s appendString:v.expansion];
            }
            [s appendString:@" "];
        }
    }
    return s;
}

- (void) setExpansionDesc:(NSString *)desc
{
    NSScanner *scan = [NSScanner scannerWithString:desc];
    [scan setCharactersToBeSkipped:nil];
    NSString *s;
    
    [scan scanUpToString:@"~" intoString:&s];
    self.expansion = s;
    
    if (![scan scanString:@"~" intoString:nil]) {
        self.variants = nil;
    }
    else {
        NSMutableArray *vv = [NSMutableArray arrayWithCapacity:2];
        NSString *x;
        NSCharacterSet *nameDelims = [NSCharacterSet characterSetWithCharactersInString:@" \t="];
        while ([scan scanUpToCharactersFromSet:nameDelims intoString:&s]) {
            if ([scan scanString:@"=" intoString:nil]) {
                [scan scanUpToCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:&x];
            }
            else {
                x = s;
            }
            if ([s length]) {
                AbbrevBase *v = [[AbbrevBase alloc] init];
                v.abbreviation = s;
                v.expansion = x;
                [vv addObject:v];
            }
            [scan scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:nil];
        }
        self.variants = vv;
    }
}

- (NSString*) variantAbbreviation:(AbbrevBase*)variant
{
    return [self.abbreviation stringByAppendingString:variant.abbreviation];
}

- (NSString*) variantExpansion:(AbbrevBase*)variant
{
    NSString *se = self.expansion;
    NSString *ve = variant.expansion;
    if ([ve length] == 0) {
        return se;
    }
    unichar prefix = [ve characterAtIndex:0];
    if ((prefix != '<') && (prefix != '>')) {
        return [se stringByAppendingString:ve];
    }
    
    unsigned origLength = [se length], addLength = [ve length] - 1;
    if (prefix == '<') {
        if (origLength > 0) {
            origLength--;
        }
    }
    else if (prefix == '>') {
        if (origLength > 0) {
            addLength++;
        }
    }
    NSMutableString *s = [NSMutableString stringWithCapacity:(origLength + addLength)];
    [s appendString:[se substringToIndex:origLength]];
    if (prefix == '>') {
        [s appendString:[se substringWithRange:NSMakeRange(origLength - 1, 1)]];
    }
    [s appendString:[ve substringFromIndex:1]];
    return s;
}

//
//	NSCoding methods
//

- (id) initWithCoder:(NSCoder*)coder
{
	self = [super initWithCoder:coder];
	if (self != nil) {
        self.variants = [coder decodeObjectForKey:@"var"];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder*)coder
{
    [super encodeWithCoder:coder];
    if (variants) {
        [coder encodeObject:variants forKey:@"var"];
	}
}

@end

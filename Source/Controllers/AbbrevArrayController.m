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

#import "AbbrevArrayController.h"
#import "AbbrevEntry.h"
#import "AbbrevListDocument.h"


#define DefaultAbbrevsKey @"DefaultAbbrevations"


@implementation AbbrevArrayController

- (void) dealloc
{
	[super dealloc];
}

- (void) awakeFromNib
{
	NSData *data = [[NSUserDefaults standardUserDefaults] dataForKey:DefaultAbbrevsKey];
    if (data) {
        [self addObjects:[NSKeyedUnarchiver unarchiveObjectWithData:data]];
        [document modified];
    }			
}

- (void) delete:(id)sender
{
    if ([self selectionIndex] != NSNotFound) {
        [self removeObjects:[self selectedObjects]];
        [self persist];
    }
}

- (void) add:(id)sender
{
	[super add:sender];
    [self persist];
}

- (void) remove:(id)sender
{
	[super remove:sender];
    [self persist];
}

- (void) copy:(id)sender
{
    NSArray *selectedObjects = [self selectedObjects];
    NSUInteger count = [selectedObjects count];
    if (count == 0) {
        return;
    }
    NSMutableArray *copyObjectsArray = [NSMutableArray arrayWithCapacity: count];
    NSMutableString *textBuffer = [NSMutableString stringWithCapacity:2000];
        
    for (AbbrevEntry *a in selectedObjects) {
        [copyObjectsArray addObject: a];
        if (a.abbreviation && a.abbreviation.length && a.expansion) {
            [textBuffer appendString:a.abbreviation];
            [textBuffer appendString:@"\t"];
            [textBuffer appendString:a.expansion];
            [textBuffer appendString:@"\n"];
        }
    }
    
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    [pb declareTypes:[NSArray arrayWithObjects:AbbreviationsPasteboardType, NSPasteboardTypeString, nil] owner:self];
    
    NSData *copyData = [NSKeyedArchiver archivedDataWithRootObject:copyObjectsArray];
    [pb setData:copyData forType:AbbreviationsPasteboardType];
    
    [pb setString:textBuffer forType:NSPasteboardTypeString];
}

- (void) paste:(id)sender
{
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    NSData *data = [pb dataForType: AbbreviationsPasteboardType];
    NSArray *items = nil;
    
    if (data != nil) {
        items = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
    else {
        NSString *s = [pb stringForType: NSPasteboardTypeString];
        if (s != nil) {
            NSScanner *scan = [NSScanner scannerWithString:s];
            NSMutableArray *aa = [NSMutableArray array];
            while (![scan isAtEnd]) {
                [scan scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:nil];
                NSString *n;
                if ([scan scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&n]) {
                    NSString *v;
                    if ([scan scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:&v]) {
                        AbbrevEntry *a = [self newEntry];
                        a.abbreviation = n;
                        a.expansionDesc = v;
                        [aa addObject:a];
                    }
                }
            }
            items = aa;
        }
    }

    if (items != nil && [items count] > 0) {
        NSUInteger pos = [self selectionIndex];
        if (pos == NSNotFound) {
            pos = [[self arrangedObjects] count];
        }
        for (AbbrevEntry *a in items) {
            [self insertObject:a atArrangedObjectIndex:pos];
            pos++;
        }
        [self persist];
    }
}

- (void) objectDidEndEditing:(id)editor
{
	[super objectDidEndEditing:editor];
    [self persist];
}

- (AbbrevEntry*) newEntry
{
    AbbrevEntry* e = [[AbbrevEntry alloc] init];
    e.abbreviation = @"";
    e.expansion = @"";
    return e;
}

- (void) persist
{
    [document modified];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:[self arrangedObjects]];
	[[NSUserDefaults standardUserDefaults] setObject:data forKey:DefaultAbbrevsKey];
}

@end

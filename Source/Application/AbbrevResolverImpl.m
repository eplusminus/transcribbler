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

#import "AbbrevResolverImpl.h"

#import "AbbrevListDocument.h"


@implementation AbbrevResolverImpl

- (id)init
{
  self = [super init];
  documents = [[NSMutableArray arrayWithCapacity:10] retain];
  return self;
}

- (void)dealloc
{
  [index release];
  [documents release];
  [super dealloc];
}

- (void)addedDocument:(AbbrevListDocument*)document
{
  [documents addObject:document];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh:)
                                               name:AbbrevListDocumentModified object:document];
  [self refresh:nil];
}

- (void)refresh:(id)sender
{
  NSArray* items = nil;
  for (AbbrevListDocument* d in documents) {
    NSArray* a = [d.controller arrangedObjects];
    if (items) {
      items = [items arrayByAddingObjectsFromArray:a];
    }
    else {
      items = a;
    }
  }
  
  [self setItems:items];
}

- (void)setItems:(NSArray*)newItems
{
  NSMutableDictionary *newIndex = [NSMutableDictionary dictionaryWithCapacity:[newItems count]];
  for (AbbrevEntry *a in newItems) {
    [self addToIndex:newIndex value:a forKey:a.abbreviation];
    if (a.variants != nil) {
      for (AbbrevBase *v in a.variants) {
        [self addToIndex:newIndex value:a forKey:[a variantAbbreviation:v]];
      }
    }
  }
  [index release];
  index = [newIndex retain];
}

- (void)addToIndex:(NSMutableDictionary*)newIndex value:(id)value forKey:(NSString*)key
{
  if (key == nil || value == nil) {
    return;
  }
  NSString *k = [key lowercaseString];
  NSObject *existing = [newIndex valueForKey:k];
  if (existing == nil) {
    [newIndex setValue:value forKey:k];
  }
  else {
    NSArray *na;
    if ([existing isMemberOfClass:[NSArray class]]) {
      na = [((NSArray*)existing) arrayByAddingObject:value];
    }
    else {
      na = [NSArray arrayWithObjects:existing, value, nil];
    }
    [newIndex setValue:na forKey:k];
  }
}

//
// protocol AbbrevResolver
//

- (NSString*)getExpansion:(NSString*)abbrev
{
  NSString *key = [abbrev lowercaseString];
  NSObject *found = [index valueForKey:[abbrev lowercaseString]];
  if (found != nil && [found isMemberOfClass:[AbbrevEntry class]]) {
    AbbrevEntry *a = (AbbrevEntry *)found;
    if ([a.abbreviation caseInsensitiveCompare:key] == NSOrderedSame) {
      return a.expansion;
    }
    else {
      for (AbbrevBase *v in a.variants) {
        if ([[a variantAbbreviation:v] caseInsensitiveCompare:key] == NSOrderedSame) {
            return [a variantExpansion:v];
        }
      }
    }
  }
  return nil;
}

- (BOOL)hasDuplicateAbbreviation:(AbbrevEntry*)a
{
  if ([self isDuplicate:a.abbreviation]) {
    return YES;
  }
  if (a.variants != nil) {
    for (AbbrevBase *v in a.variants) {
      if ([self isDuplicate:[a variantAbbreviation:v]]) {
        return YES;
      }
    }
  }
  return NO;
}

- (BOOL)isDuplicate:(NSString*)abbrev
{
  return [[index valueForKey:[abbrev lowercaseString]] isKindOfClass:[NSArray class]];
}

@end

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

#import "TransTextDocument.h"

#import "AbbrevsController.h"
#import "AppDelegate.h"
#import "MediaController.h"
#import "TransTextWindowController.h"
#import "TransTextView.h"


@implementation TransTextDocument

#define kWindowPosCommentParam @"WindowPos"
#define kMediaFilePathCommentParam @"MediaFile"
#define kTimeCodeCommentParam @"TimeCode"
#define kMediaDrawerOpenCommentParam @"MediaDrawerOpen"
#define kAbbrevDrawerOpenCommentParam @"AbbrevDrawerOpen"

#define kCommentParamFieldStart @"{$$"
#define kCommentParamFieldEnd @"$$}"
#define kCommentParamFieldDelim @"="

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
  
  [[windowController abbrevsController] addAbbrevListDocument:abbrevListDocument];
  [windowController textView].abbrevResolver = abbrevResolver;

  [self useLoadedText];
}
	
- (BOOL)readFromFileWrapper:(NSFileWrapper*)file ofType:(NSString*)type error:(NSError**)error
{
  NSDictionary* docAttrs;
	loadedText = [[[NSAttributedString alloc] initWithRTF:[file regularFileContents] documentAttributes:&docAttrs] retain];
  loadedDocAttributes = [docAttrs retain];
  
  if (loadedText) {
    [self useLoadedText];
  }
  
	return YES;
}

- (NSFileWrapper*)fileWrapperOfType:(NSString*)type error:(NSError**)error
{
  NSDictionary* attrs = [self makeDocAttributes];
  NSData* data = [textStorage RTFFromRange:NSMakeRange(0, [[textStorage string] length])  documentAttributes:attrs];
	NSFileWrapper* file = [[NSFileWrapper alloc] initRegularFileWithContents:data];
	
  return [file autorelease];
}

//
// internal
//

- (void)useLoadedText
{
  if (loadedText && textStorage) {
    [textStorage replaceCharactersInRange:NSMakeRange(0, [textStorage length]) withAttributedString:loadedText];
    [loadedText release];
    loadedText = nil;
  }

  if (loadedDocAttributes && windowController) {
    [self readDocAttributes:loadedDocAttributes];
    [loadedDocAttributes release];
    loadedDocAttributes = nil;
  }
}

- (void)readDocAttributes:(NSDictionary*)attrs
{
  NSDictionary* commentParams = [TransTextDocument parseCommentParams:[attrs objectForKey:NSCommentDocumentAttribute] remainingComment:nil];
  
  NSString* wp = [commentParams objectForKey:kWindowPosCommentParam];
  if (wp) {
    NSRect r = NSRectFromString(wp);
    if (r.size.width > 0) {
      [[windowController window] setFrame:r display:YES];
    }
  }
  
  MediaController* mc = [windowController mediaController];

  NSString* mfp = [commentParams objectForKey:kMediaFilePathCommentParam];
  if (mfp) {
    [mc openMediaFile:mfp];
  }
  
  NSString* tc = [commentParams objectForKey:kTimeCodeCommentParam];
  if (tc) {
    [mc setTimeCodeString:tc];
  }
  
  if ([commentParams objectForKey:kMediaDrawerOpenCommentParam]) {
    [windowController setMediaDrawerOpen:YES];
  }
  
  if ([commentParams objectForKey:kAbbrevDrawerOpenCommentParam]) {
    [windowController setAbbrevDrawerOpen:YES];
  }
}

- (NSDictionary*)makeDocAttributes
{
  NSMutableDictionary* attrs = [NSMutableDictionary dictionaryWithCapacity:10];
  [attrs setObject:NSRTFTextDocumentType forKey:NSDocumentTypeDocumentAttribute];

  NSMutableDictionary* commentParams = [NSMutableDictionary dictionaryWithCapacity:10];
  
  [commentParams setObject:NSStringFromRect([[windowController window] frame]) forKey:kWindowPosCommentParam];
  
  MediaController* mc = [windowController mediaController];
  
  if ([mc mediaFilePath]) {
    [commentParams setObject:[[windowController mediaController] mediaFilePath] forKey:kMediaFilePathCommentParam];
  }
  
  if ([mc movie]) {
    [commentParams setObject:[mc timeCodeString] forKey:kTimeCodeCommentParam];
  }
  
  if ([windowController isMediaDrawerOpen]) {
    [commentParams setObject:@"" forKey:kMediaDrawerOpenCommentParam];
  }
  
  if ([windowController isAbbrevDrawerOpen]) {
    [commentParams setObject:@"" forKey:kAbbrevDrawerOpenCommentParam];
  }
  
  NSMutableString* comment = [NSMutableString stringWithCapacity:200];
  for (NSString* name in [commentParams keyEnumerator]) {
    [comment appendString:kCommentParamFieldStart];
    [comment appendString:name];
    [comment appendString:kCommentParamFieldDelim];
    [comment appendString:[commentParams objectForKey:name]];
    [comment appendString:kCommentParamFieldEnd];
  }
  if ([comment length]) {
    [attrs setObject:[NSString stringWithString:comment] forKey:NSCommentDocumentAttribute];
  }
  return [NSDictionary dictionaryWithDictionary:attrs];
}

+ (NSDictionary*)parseCommentParams:(NSString*)comment remainingComment:(NSString**)commentOut
{
  if (!comment) {
    if (commentOut) {
      *commentOut = nil;
    }
    return [NSDictionary dictionary];
  }
  
  NSMutableDictionary* params = [NSMutableDictionary dictionaryWithCapacity:10];
  NSMutableString* commentBuf = [NSMutableString stringWithCapacity:[comment length]];
  NSScanner* scan = [NSScanner scannerWithString:comment];
  [scan setCharactersToBeSkipped:nil];
  NSCharacterSet* fieldDelim = [NSCharacterSet characterSetWithCharactersInString:kCommentParamFieldDelim];
  while (![scan isAtEnd]) {
    NSString* s;
    if ([scan scanUpToString:kCommentParamFieldStart intoString:&s]) {
      [commentBuf appendString:s];
    }
    if ([scan scanString:kCommentParamFieldStart intoString:nil]) {
      NSString* name;
      if ([scan scanUpToCharactersFromSet:fieldDelim intoString:&name] &&
          [scan scanCharactersFromSet:fieldDelim intoString:nil]) {
        NSString* value = @"";
        [scan scanUpToString:kCommentParamFieldEnd intoString:&value];
        if ([scan scanString:kCommentParamFieldEnd intoString:nil]) {
          [params setObject:value forKey:name];
        }
      }
    }
  }
  if (commentOut) {
    *commentOut = [NSString stringWithString:commentBuf];
  }
  return [NSDictionary dictionaryWithDictionary:params];
}

@end

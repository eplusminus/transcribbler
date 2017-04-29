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
#import "AbbreviationsEditor/AbbreviationsEditor-Swift.h"

#import "TransTextDocument.h"

#import "AppDelegate.h"
#import "TransTextWindowController.h"


@implementation TransTextDocument

#define kWindowPosCommentParam @"WindowPos"
#define kMediaFilePathCommentParam @"MediaFile"
#define kTimeCodeCommentParam @"TimeCode"
#define kMediaDrawerOpenCommentParam @"MediaDrawerOpen"
#define kAbbrevDrawerOpenCommentParam @"AbbrevDrawerOpen"

@synthesize abbrevListDocument, abbrevResolver;

- (id)init
{
  self = [super init];
  abbrevListDocument = [[AbbrevListDocument alloc] init];
  abbrevResolver = [[AbbrevResolverImpl alloc] init];
  [abbrevResolver addProvider:abbrevListDocument];
  abbrevListDocument.abbrevResolver = abbrevResolver;
  return self;
}

- (void)makeWindowControllers
{
  windowController = [[TransTextWindowController alloc] initWithWindowNibName:@"TransTextDocument"];
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
	loadedText = [[NSAttributedString alloc] initWithRTF:[file regularFileContents] documentAttributes:&docAttrs];
  loadedDocAttributes = docAttrs;
  
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
	
  return file;
}

//
// internal
//

- (void)useLoadedText
{
  if (loadedText && textStorage) {
    [textStorage replaceCharactersInRange:NSMakeRange(0, [textStorage length]) withAttributedString:loadedText];
    loadedText = nil;
  }

  if (loadedDocAttributes && windowController) {
    [self readDocAttributes:loadedDocAttributes];
    loadedDocAttributes = nil;
  }
}

- (void)readDocAttributes:(NSDictionary*)attrs
{
  NSString* paramsString = [[attrs objectForKey: NSCommentDocumentAttribute] string];
  NSString* leftover;
  NSDictionary* commentParams = [CommentStringFields paramsFromString: paramsString remainingString: &leftover];
  
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
    [mc openMediaFileWithFilePath:mfp error:nil];
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
  
  NSString* comment = [CommentStringFields stringFromParams:commentParams];
  if ([comment length]) {
    [attrs setObject:[NSString stringWithString:comment] forKey:NSCommentDocumentAttribute];
  }
  return [NSDictionary dictionaryWithDictionary:attrs];
}

@end

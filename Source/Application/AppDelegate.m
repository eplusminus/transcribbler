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

#import "AppDelegate.h"
#import "AbbrevListDocument.h"

@implementation AppDelegate

@synthesize abbrevResolver;

- (id) init
{
    self = [super init];
    abbrevResolver = [[[AbbrevResolverImpl alloc] init] retain];
    return self;
}

- (NSRect) windowZoomRect
{
    NSRect desktopFrame = [[appControlPanel screen] visibleFrame];
    NSRect panelFrame = [appControlPanel frame];
    return NSMakeRect(desktopFrame.origin.x + panelFrame.size.width, desktopFrame.origin.y,
                      desktopFrame.size.width - panelFrame.size.width, desktopFrame.size.height);
}

- (void) applicationDidFinishLaunching:(NSNotification *)notification
{
    [NSBundle loadNibNamed:@"ControlPanelWindow" owner:self];
    
    NSRect desktopFrame = [[appControlPanel screen] visibleFrame];
    [appControlPanel setFrame:NSMakeRect(desktopFrame.origin.x,
                                         desktopFrame.origin.y,
                                         [appControlPanel frame].size.width,
                                         desktopFrame.size.height)
                      display:YES];
    [appControlPanel orderBack:self];

    [[[NSNib alloc] initWithNibNamed:@"MediaPanelView" bundle:[NSBundle mainBundle]] instantiateNibWithOwner:self topLevelObjects:nil];
    [[appControlPanel modules] addSubview:mediaController.mediaPanel setsOwnSize:YES];
    
    AbbrevListDocument* ald = [[AbbrevListDocument alloc] init];
    [abbrevResolver addedDocument:ald];
    
    NSNib* nib = [[NSNib alloc] initWithNibNamed:@"AbbrevListView" bundle:[NSBundle mainBundle]];
    [nib instantiateNibWithOwner:ald topLevelObjects:nil];
    [[appControlPanel modules] addSubview:[ald view] setsOwnSize:NO];
    
    [NSApp setNextResponder:mediaController];
}

- (IBAction) openDocument:(id)sender
{
    NSOpenPanel* aPanel = [NSOpenPanel openPanel];
	NSArray* types = [QTMovie movieFileTypes:0xfff];
    NSURL* url;
    
    [aPanel setAllowedFileTypes:types];
    [aPanel runModal];
    url = [aPanel URL];
    if (url) {
        [self application:NSApp openFile:[url path]];
    }
}

- (BOOL) application:(NSApplication*)app openFile:(NSString*)filename
{
    NSWorkspace* ws = [NSWorkspace sharedWorkspace];
    NSURL *fileURL = [NSURL fileURLWithPath:filename];
    NSString *fileUTI = nil;
    
    [fileURL getResourceValue:&fileUTI forKey:NSURLTypeIdentifierKey error:NULL];
    
    if (fileUTI) {
        NSArray* types = [QTMovie movieTypesWithOptions:QTIncludeCommonTypes];
        for (NSString* movieType in types) {
            if ([ws type:fileUTI conformsToType:movieType]) {
                return [mediaController openFile:filename];
            }
        }
    }
    
    return NO;
}

@end

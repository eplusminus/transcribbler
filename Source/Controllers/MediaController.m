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

#import "MediaController.h"


@implementation MediaController

@synthesize mediaPanel;

- (void) dealloc
{
    [mediaPanel release];
    [movie release];
    [super dealloc];
}

- (BOOL) isPlaying
{
    return movie && ([movie rate] != 0);
}

- (BOOL) openFile:(NSString*)filename
{
    NSError* error;
    QTMovie* m = [QTMovie movieWithFile:filename error:&error];
    if (error || !m) {
        return NO;
    }
    
    [mediaPanel setMovieName:[[filename lastPathComponent] stringByDeletingPathExtension]];
    [mediaPanel setMovie:m];
    [movie release];
    movie = [m retain];
    
    return YES;
}

- (IBAction) pause:(id)sender
{
    if ([self isPlaying]) {
        [movie stop];
    }
}

- (IBAction) play:(id)sender
{
    if (movie && ![self isPlaying]) {
        [movie play];
    }
}

- (IBAction) togglePlay:(id)sender
{
    if (movie) {
        if ([self isPlaying]) {
            [self pause:sender];
        }
        else {
            [self play:sender];
        }
    }
}

- (IBAction) replay:(id)sender
{
    if (movie) {
        QTTime decrement = QTMakeTime(1, 1);
        [movie setCurrentTime:QTTimeDecrement([movie currentTime], decrement)];
        [self play:sender];
    }
}

- (BOOL) validateMenuItem:(NSMenuItem*)menuItem
{
    if ([menuItem action] == @selector(togglePlay:)) {
        NSString* name = [self isPlaying] ? @"Pause" : @"Play";
        [menuItem setTitle:NSLocalizedString(name, nil)];
        return (movie != nil);
    }
    return NO;
}

@end

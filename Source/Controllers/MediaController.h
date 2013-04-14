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

#import "MediaPanel.h"

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>


@interface MediaController : NSResponder {
    
    IBOutlet MediaPanel* mediaPanel;
    
    QTMovie* movie;
}

@property(readonly) MediaPanel* mediaPanel;

- (BOOL) isPlaying;

- (BOOL) openFile:(NSString*)filename;

- (IBAction) pause:(id)sender;
- (IBAction) play:(id)sender;
- (IBAction) replay:(id)sender;
- (IBAction) togglePlay:(id)sender;

@end

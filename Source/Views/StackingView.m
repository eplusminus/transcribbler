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

#import "StackingView.h"


@interface StackingViewProperties : NSObject {
    @public
    BOOL setsOwnSize;
}
@end

@implementation StackingViewProperties
@end


@implementation StackingView

- (void) dealloc
{
    [viewProperties release];
    [super dealloc];
}

- (void) addSubview:(NSView*)view setsOwnSize:(BOOL)setsOwnSize
{
    StackingViewProperties* p = [[StackingViewProperties alloc] init];
    p->setsOwnSize = setsOwnSize;
    
    if (!viewProperties) {
        viewProperties = [[NSMutableDictionary dictionary] retain];
    }
    
    [viewProperties setObject:p forKey:[NSValue valueWithNonretainedObject:view]];

    if (setsOwnSize) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateLayout:) name:NSViewFrameDidChangeNotification object:view];
    }
    
    [self addSubview:view];
    [self updateLayout:self];
}

- (void) updateLayout:(id)sender
{
    float fixedWidth = [self frame].size.width;
    float availableHeight = [self frame].size.height;
    int varHeightCount = 0;
    for (NSView* v in [self subviews]) {
        StackingViewProperties* p = [viewProperties objectForKey:[NSValue valueWithNonretainedObject:v]];
        if (p) {
            if (p->setsOwnSize) {
                availableHeight -= [v frame].size.height;
            }
            else {
                varHeightCount++;
            }
        }
    }
    
    float pos = [self frame].size.height;
    for (NSView* v in [self subviews]) {
        float newHeight;
        StackingViewProperties* p = [viewProperties objectForKey:[NSValue valueWithNonretainedObject:v]];
        if (p->setsOwnSize) {
            newHeight = [v frame].size.height;
        }
        else {
            newHeight = availableHeight / varHeightCount;
        }
        [v setFrame:NSMakeRect(0, pos - newHeight, fixedWidth, newHeight)];
        pos -= newHeight;
    }
    
    [self setNeedsDisplay:YES];
}

@end

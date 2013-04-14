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


@implementation MediaPanel

- (void) dealloc
{
    [movie release];
    [super dealloc];
}

- (void) awakeFromNib
{
    [divider setFrameSize:NSMakeSize([divider frame].size.width, 1)];
    
    [self updateState:nil];
}

- (QTMovie*) movie
{
    return movie;
}

- (void) setMovie:(QTMovie*)newMovie
{
    [movieView setMovie:newMovie];
    [movie release];
    movie = [newMovie retain];
    [self updateState:nil];
    if (movie) {
        if (!timer || ![timer isValid]){
            timer = [[NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(timerTask:) userInfo:nil repeats:YES] retain];
            [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
        }
    }
    else {
        [timer invalidate];
        [timer release];
        timer = nil;
    }
}

- (void) setMovieName:(NSString*)name
{
    [fileNameLabel setStringValue:name];
}

- (void) timerTask:(id)sender
{
    if (movie && [movie isIdling]) {
        [self updateTimeCode];
    }
}

- (IBAction) updateState:(id)sender
{
    NSRect viewFrame = [self frame];
    float fixedHeight = viewFrame.size.height - [divider frame].origin.y;
    float fixedWidth = viewFrame.size.width;
    if (movie) {
        [twixie setHidden:NO];
        [fileNameLabel setHidden:NO];
        [timeCodeLabel setHidden:NO];
        [self updateTimeCode];
        
        float controllerHeight = [movieView controllerBarHeight];
        
        if ([twixie state]) {
            BOOL hasVideo = [[movie attributeForKey:QTMovieHasVideoAttribute] boolValue];
            int moviePanelHeight;
            if (hasVideo) {
                NSSize size = [[movie attributeForKey:QTMovieNaturalSizeAttribute] sizeValue];
                moviePanelHeight = (fixedWidth * size.height) / size.width;
            }
            else {
                moviePanelHeight = 50;
            }
            float movieViewHeight = moviePanelHeight + controllerHeight;
            [movieView setFrameSize:NSMakeSize(fixedWidth, movieViewHeight)];
            [self setFrameSize:NSMakeSize(fixedWidth, fixedHeight + movieViewHeight)];
            
            if (hasVideo) {
                [noVideoLabel setHidden:YES];
            }
            else {
                float labelHeight = [noVideoLabel frame].size.height;
                [noVideoLabel setFrame:NSMakeRect(0, controllerHeight + (moviePanelHeight - labelHeight) / 2,
                                                  fixedWidth, labelHeight)];
                [noVideoLabel setHidden:NO];
            }
        }
        else {
            [noVideoLabel setHidden:YES];
            [movieView setFrameSize:NSMakeSize(fixedWidth, controllerHeight)];
            [self setFrameSize:NSMakeSize(fixedWidth, fixedHeight + controllerHeight)];
        }
        [movieView setHidden:NO];
        [self setNeedsDisplay:YES];
    }
    else {
        [twixie setHidden:YES];
        [fileNameLabel setHidden:YES];
        [timeCodeLabel setHidden:YES];
        [movieView setHidden:YES];
        [noVideoLabel setHidden:YES];
        [self setFrameSize:NSMakeSize(fixedWidth, fixedHeight)];
    }
}

- (void) updateTimeCode
{
    QTTime current = [movie currentTime];
	[timeCodeLabel setStringValue:[self timeString:current]];
}

- (NSString*) timeString:(QTTime)time
{
    long secondsTimes10 = (time.timeValue * 10) / time.timeScale;
    int t = secondsTimes10 % 10;
    long seconds = secondsTimes10 / 10;
    int ss = seconds % 60;
    long minutes = seconds / 60;
    int mm = minutes % 60;
    int hh = minutes / 60;
    
	return [NSString stringWithFormat:@"%02d:%02d:%02d.%d", hh, mm, ss, t];
}

@end

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

#import "MediaController.h"

#import "DisclosureView.h"
#import "StackingView.h"


@implementation MediaController

- (id)initWithCoder:(NSCoder*)aDecoder
{
  self = [super initWithCoder:aDecoder];
  [NSBundle loadNibNamed:@"MediaDrawerView" owner:self];
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:stackingView];
  [movie release];
  [timer invalidate];
  [timer release];
  [super dealloc];
}

- (void)awakeFromNib
{
  if (drawer && [drawer contentView] != [self view]) {
    NSSize size = [[self view] frame].size;
    [[self view] setAutoresizesSubviews:YES];
    [drawer setContentSize:size];
    [drawer setMinContentSize:size];
    [drawer setContentView:[self view]];
  }
  
  [self showMovieFileName];
  [movieDisclosureView setHidden:YES];
  [propertiesDisclosureView setHidden:YES];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stackingViewFrameChanged:) name:NSViewFrameDidChangeNotification object:stackingView];
  
  if (!timer){
    timer = [[NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(timerTask:) userInfo:nil repeats:YES] retain];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
  }
}

- (QTMovie*)movie
{
  return movie;
}

- (void)setMovie:(QTMovie*)m
{
  if (movie != m) {
    [movie release];
    movie = [m retain];
    [movieView setMovie:m];
    
    if (movie) {
      hasVideo = [[movie attributeForKey:QTMovieHasVideoAttribute] boolValue];
      [movieDisclosureView setTitle:NSLocalizedString(hasVideo ? @"Video" : @"AudioOnly", nil)];
      [movieDisclosureView setHidden:NO];
      [self updateMovieViewSize];
      
      QTTime totalTime = [[movie attributeForKey:QTMovieDurationAttribute] QTTimeValue];
      long long fileSize = [[movie attributeForKey:QTMovieDataSizeAttribute] longLongValue];
      [totalTimeLabel setStringValue:[MediaController timeString: totalTime withTenths:NO]];
      [fileSizeLabel setStringValue:[MediaController fileSizeString:fileSize]];
      [propertiesDisclosureView setHidden:NO];

      lastTimeValue = -1;
    }
    else {
      [movieDisclosureView setHidden:YES];
      [propertiesDisclosureView setHidden:YES];
      [timeCodeLabel setStringValue:@""];
    }
  }
}

- (IBAction) loadMedia:(id)sender
{
  NSOpenPanel* aPanel = [NSOpenPanel openPanel];
	NSArray* types = [QTMovie movieFileTypes:0xfff];
  NSURL* url;
  
  [aPanel setAllowedFileTypes:types];
  [aPanel runModal];
  url = [aPanel URL];
  if (url) {
    [self openMediaFile:[url path]];
  }
}

- (BOOL)openMediaFile:(NSString*)filePath
{
  if ([movieFilePath isEqualToString:filePath]) {
    return YES;
  }
  
  NSError* error;
  QTMovie* m = [QTMovie movieWithFile:filePath error:&error];
  if (error || !m) {
    return NO;
  }
  
  [movieFilePath release];
  movieFilePath = [filePath retain];

  [self showMovieFileName];
  [self setMovie:m];
  
  return YES;
}

- (void)closeMediaFile
{
  if (movie) {
    [self setMovie:nil];
    [movieFilePath release];
    movieFilePath = nil;
  }
}

- (BOOL)isPlaying
{
  return movie && ([movie rate] != 0);
}


- (IBAction)pause:(id)sender
{
  if ([self isPlaying]) {
    [movie stop];
  }
}

- (IBAction)play:(id)sender
{
  if (movie && ![self isPlaying]) {
    [movie play];
  }
}

- (IBAction)togglePlay:(id)sender
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

- (IBAction)replay:(id)sender
{
  if (movie) {
    QTTime decrement = QTMakeTime(1, 1);
    [movie setCurrentTime:QTTimeDecrement([movie currentTime], decrement)];
    [self play:sender];
  }
}

//
// informal protocol NSMenuValidation
//

- (BOOL) validateMenuItem:(NSMenuItem*)menuItem
{
  if ([menuItem action] == @selector(togglePlay:)) {
    NSString* name = [self isPlaying] ? @"Pause" : @"Play";
    [menuItem setTitle:NSLocalizedString(name, nil)];
    return (movie != nil);
  }
  if ([menuItem action] == @selector(loadMedia:)) {
    return YES;
  }
  return NO;
}

//
// internal use
//

- (void)timerTask:(id)sender
{
  [self updateTimeCode];
}

- (void)updateTimeCode
{
  if (movie) {
    QTTime current = [movie currentTime];
    if (current.timeValue != lastTimeValue) {
      lastTimeValue = current.timeValue;
      [timeCodeLabel setStringValue:[MediaController timeString:current withTenths:YES]];
    }
  }
}

- (void)showMovieFileName
{
  if (movieFilePath) {
    [fileNameLabel setStringValue:[[movieFilePath lastPathComponent] stringByDeletingPathExtension]];
  }
  else {
    [fileNameLabel setStringValue:NSLocalizedString(@"NoMediaFile", nil)];
  }
}

- (void)updateMovieViewSize
{
  if (hasVideo) {
    NSSize size = [[movie attributeForKey:QTMovieNaturalSizeAttribute] sizeValue];
    int moviePanelHeight = ([movieDisclosureView frame].size.width * size.height) / size.width;
    [movieDisclosureView setPreferredHeight:moviePanelHeight];
  } else {
    [movieDisclosureView setPreferredHeight:[movieView controllerBarHeight]];
  }
}

- (void)stackingViewFrameChanged:(id)sender
{
  [self updateMovieViewSize];
}

+ (NSString*)timeString:(QTTime)time withTenths:(BOOL)withTenths
{
  long secondsTimes10 = (time.timeValue * 10) / time.timeScale;
  int t = secondsTimes10 % 10;
  long seconds = secondsTimes10 / 10;
  int ss = seconds % 60;
  long minutes = seconds / 60;
  int mm = minutes % 60;
  int hh = minutes / 60;
  
  if (withTenths) {
    return [NSString stringWithFormat:@"%02d:%02d:%02d.%d", hh, mm, ss, t];
  }
  else {
    return [NSString stringWithFormat:@"%02d:%02d:%02d", hh, mm, ss];
  }
}

+ (NSString*)fileSizeString:(long long)bytes
{
  long long k = bytes / 1024;
  if (k < 1024) {
    return [NSString stringWithFormat:@"%lldK", k];
  }
  else {
    return [NSString stringWithFormat:@"%lldM", k / 1024];
  }
}

@end

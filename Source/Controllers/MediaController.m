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
#import "ViewSizeLimits.h"


@interface MiniTimecodeView : NSView <ViewSizeLimits> {
 @private
  IBOutlet NSTextField* timeCodeLabel;
  NSSize minSize;
}
- (void)setTimeCodeString:(NSString*)s;
@end


@implementation MediaController

- (id)initWithCoder:(NSCoder*)aDecoder
{
  self = [super initWithCoder:aDecoder];
  [NSBundle loadNibNamed:@"MediaDrawerView" owner:self];
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:movieDisclosureView];
  [movie release];
  [timer invalidate];
  [timer release];
  
  if ([miniTimecodeView superview] == nil) {
    [miniTimecodeView release];
  }
  
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
  [miniTimecodeView setHidden:YES];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewResized:) name:NSViewFrameDidChangeNotification object:movieDisclosureView];
  
  if (!timer){
    timer = [[NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(timerTask:) userInfo:nil repeats:YES] retain];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
  }
}

- (AVAsset*)movie
{
  return movie;
}

- (void)setMovie:(AVAsset*)m
{
  if (movie != m) {
    [movie release];
    movie = [m retain];
    [player release];
    AVPlayerItem* playerItem = [AVPlayerItem playerItemWithAsset:movie];
    player = [AVPlayer playerWithPlayerItem: playerItem];
    [movieView setPlayer:player];
    
    if (movie) {
      hasVideo = ([movie tracksWithMediaCharacteristic: AVMediaCharacteristicVisual].count > 0);
      [movieDisclosureView setTitle:NSLocalizedString(hasVideo ? @"Video" : @"AudioOnly", nil)];
      [movieDisclosureView setHidden:NO];
      [self updateMovieViewSize];
      
      CMTime totalTime = [movie duration];
      long long fileSize = 0; // [[movie attributeForKey:QTMovieDataSizeAttribute] longLongValue];
      [totalTimeLabel setStringValue:[MediaController timeString: totalTime withTenths:NO]];
      [fileSizeLabel setStringValue:[MediaController fileSizeString:fileSize]];
      [propertiesDisclosureView setHidden:NO];
      [miniTimecodeView setHidden:NO];
      
      lastTimeValue = -1;
    }
    else {
      [movieDisclosureView setHidden:YES];
      [propertiesDisclosureView setHidden:YES];
      [timeCodeLabel setStringValue:@""];
      [miniTimecodeView setTimeCodeString:@""];
      [miniTimecodeView setHidden:YES];
    }
  }
}

- (IBAction) loadMedia:(id)sender
{
  NSOpenPanel* aPanel = [NSOpenPanel openPanel];
  NSURL* url;
  
  [aPanel setAllowedFileTypes:[AVURLAsset audiovisualTypes]];
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
  
  AVAsset* m = [AVURLAsset assetWithURL: [NSURL fileURLWithPath: filePath]];
  if (!m) {
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

- (NSString*)mediaFilePath
{
  return movieFilePath;
}

- (BOOL)isPlaying
{
  return player && ([player rate] > 0);
}

- (NSString*)timeCodeString
{
  if (movie) {
    CMTime current = [player currentTime];
    return [MediaController timeString:current withTenths:YES];
  }
  return nil;
}

- (void)setTimeCodeString:(NSString*)s
{
  if (s) {
    CMTime t = [MediaController timeFromString:s];
    [player seekToTime:t];
  }
}

- (IBAction)pause:(id)sender
{
  if ([self isPlaying]) {
    [player pause];
  }
}

- (IBAction)play:(id)sender
{
  if (movie && ![self isPlaying]) {
    [player play];
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
    CMTime decrement = CMTimeMake(1, 1);
    [player seekToTime:CMTimeSubtract([player currentTime], decrement)];
    [self play:sender];
  }
}

- (void)lendViewsTo:(StackingView*)sv
{
  [sv addSubview:miniTimecodeView];
  [movieDisclosureView removeFromSuperview];
  [sv addSubview:movieDisclosureView];
  [propertiesDisclosureView removeFromSuperview];
  [sv addSubview:propertiesDisclosureView];
}

- (void)restoreViews
{
  [miniTimecodeView removeFromSuperview];
  [movieDisclosureView removeFromSuperview];
  [stackingView addSubview:movieDisclosureView];
  [propertiesDisclosureView removeFromSuperview];
  [stackingView addSubview:propertiesDisclosureView];
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
  if (player) {
    CMTime current = [player currentTime];
    if (current.value != lastTimeValue) {
      lastTimeValue = current.value;
      NSString* ts = [MediaController timeString:current withTenths:YES];
      [timeCodeLabel setStringValue:ts];
      [miniTimecodeView setTimeCodeString:ts];
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
    NSSize size = [[[movie tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] naturalSize];
    int moviePanelHeight = ([movieDisclosureView frame].size.width * size.height) / size.width;
    [movieDisclosureView setPreferredHeight:moviePanelHeight];
  } else {
    // With AVPlayerView, unlike QTMovieView, there doesn't seem to be any way to get the height of
    // just the controller bar.  So we're getting the minimum height of the overall view instead,
    // which includes the big useless "Quicktime audio" logo; oh well.
    [movieDisclosureView setPreferredHeight:[movieView fittingSize].height];
  }
}

- (void)viewResized:(id)sender
{
  [self updateMovieViewSize];
}

+ (NSString*)timeString:(CMTime)time withTenths:(BOOL)withTenths
{
  long secondsTimes10 = CMTimeGetSeconds(time) * 10;
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

+ (CMTime)timeFromString:(NSString*)s
{
  if ([s length] == 8) {
    s = [s stringByAppendingString:@".0"];
  }
  if ([s length] == 10) {
    NSArray* fields = [s componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@":."]];
    if ([fields count] == 4) {
      int hh = [[fields objectAtIndex:0] intValue];
      int mm = [[fields objectAtIndex:1] intValue];
      int ss = [[fields objectAtIndex:2] intValue];
      int t = [[fields objectAtIndex:3] intValue];
      long value = (((((hh * 60) + mm) * 60) + ss) * 1000) + t;
      return CMTimeMake(value, 10);
    }
  }
  return CMTimeMake(0, 10);
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


@implementation MiniTimecodeView

- (void)awakeFromNib
{
  minSize = [self frame].size;
}

- (void)setTimeCodeString:(NSString*)s
{
  [timeCodeLabel setStringValue:s];
}

- (NSSize)minimumSize
{
  return minSize;
}

- (NSSize)maximumSize
{
  return minSize;
}

@end

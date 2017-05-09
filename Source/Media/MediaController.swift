/*
 
 Transcribbler, a Mac OS X text editor for audio/video transcription
 Copyright (C) 2013-2017  Eli Bishop
 
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

import HelperViews

import AVFoundation
import AVKit
import Foundation

@objc(MediaController)
public class MediaController: NSWindowController, CanBorrowViewForFullScreen {
  @IBOutlet private(set) var view: NSView?
  @IBOutlet private(set) var stackView: NSStackView!
  @IBOutlet private(set) var movieView: AVPlayerView!
  
  public var isPanelVisible: Bool {
    get {
      return window?.isVisible ?? false
    }
    set(v) {
      window?.setIsVisible(v)
    }
  }
  
  public dynamic var hasMedia: Bool = false
  public dynamic var currentTimeCodeString: String = ""
  public dynamic var totalTimeString: String = ""
  
  private var _movie: AVAsset?
  private var player: AVPlayer?
  private var timer: Timer?
  private var movieFileURL: URL?
  private var hasVideo: Bool = false
  private var lastTimeValue: CMTimeValue = 0
  private var playerSizeConstraint: NSLayoutConstraint? = nil
  private var oldResizingMask: NSAutoresizingMaskOptions = []
  
  deinit {
    disableTimer()
  }
  
  public var movie: AVAsset? {
    get {
      return _movie
    }
    set(m) {
      if _movie != m {
        _movie = m;
        
        if let actualMovie = m {
          let playerItem = AVPlayerItem(asset: actualMovie)
          player = AVPlayer(playerItem: playerItem)
          movieView.player = player
          hasVideo = actualMovie.tracks(withMediaCharacteristic: AVMediaCharacteristicVisual).count > 0
          
          updatePlayerSizeConstraint()
          
          totalTimeString = MediaController.timeString(actualMovie.duration, withTenths: false)
          
          lastTimeValue = -1
          
          hasMedia = true
          currentTimeCodeString = ""
          
          enableTimer()
        }
        else {
          hasMedia = false
          player = nil
          currentTimeCodeString = ""
          
          disableTimer()
        }
      }
    }
  }
  
  public var mediaFilePath: String? {
    get {
      return movieFileURL?.path
    }
  }
  
  @IBAction public func loadMedia(_ sender: AnyObject?) {
    let aPanel = NSOpenPanel()
    aPanel.allowedFileTypes = AVURLAsset.audiovisualTypes()
    aPanel.runModal()
    if let url = aPanel.url {
      do {
        try openMediaFile(filePath: url.path)
      }
      catch {
        // TODO
      }
    }
  }
  
  public func openMediaFile(filePath: String) throws {
    if movieFileURL?.path == filePath {
      return
    }
    let u = NSURL.fileURL(withPath: filePath)
    let m = AVURLAsset(url: u)
    
    movieFileURL = u
    updateTitle()
    self.movie = m
  }
  
  public func closeMediaFile() {
    if self.movie != nil {
      self.movie = nil
      movieFileURL = nil
    }
  }
  
  public var isPlaying: Bool {
    get {
      return (player?.rate ?? 0) > 0
    }
  }
  
  public var timeCodeString: String? {
    get {
      if movie != nil {
        if let p = player {
          return MediaController.timeString(p.currentTime(), withTenths: true)
        }
      }
      return nil
    }
    set(str) {
      if let s = str {
        if let t = MediaController.timeFromString(s) {
          player?.seek(to: t)
        }
      }
    }
  }
  
  @IBAction public func pause(_ sender: Any?) {
    if isPlaying {
      player?.pause()
    }
  }
  
  @IBAction public func play(_ sender: Any?) {
    if !isPlaying && movie != nil {
      player?.play()
    }
  }
  
  @IBAction public func togglePlay(_ sender: Any?) {
    if movie != nil {
      if isPlaying {
        pause(sender)
      }
      else {
        play(sender)
      }
    }
  }

  @IBAction public func replay(_ sender: Any?) {
    if movie != nil {
      let decrement = CMTimeMake(1, 1)
      player?.seek(to: CMTimeSubtract(player?.currentTime() ?? decrement, decrement))
      play(sender)
    }
  }
  
  //
  // internal use
  //
  
  private func enableTimer() {
    if timer == nil {
      let t = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(timerTask), userInfo: nil, repeats: true)
      timer = t
      RunLoop.current.add(t, forMode: RunLoopMode.defaultRunLoopMode)
    }
  }
  
  private func disableTimer() {
    timer?.invalidate()
    timer = nil
  }
  
  func timerTask(_ sender: Any) {
    updateTimeCode()
  }

  func updateTimeCode() {
    if let p = player {
      let current = p.currentTime()
      if current.value != lastTimeValue {
        lastTimeValue = current.value
        currentTimeCodeString = MediaController.timeString(current, withTenths: true)
      }
    }
  }

  private func updateTitle() {
    window?.representedURL = movieFileURL
    if let u = movieFileURL {
      window?.title = (u.path as NSString).lastPathComponent
    }
    else {
      window?.title = NSLocalizedString("NoMediaFile", comment: "")
    }
  }
  
  private func updatePlayerSizeConstraint() {
    if let psc = playerSizeConstraint {
      movieView.removeConstraint(psc)
      playerSizeConstraint = nil
    }
    if let m = _movie {
      var exampleSize = movieView.fittingSize
      if hasVideo {
        if let track = m.tracks(withMediaType: AVMediaTypeVideo).first {
          exampleSize = track.naturalSize
        }
      }
      let hwRatio = exampleSize.height / exampleSize.width
      let psc = NSLayoutConstraint(item: movieView, attribute: .height, relatedBy: .equal,
                                   toItem: movieView, attribute: .width, multiplier: hwRatio, constant: 0)
      playerSizeConstraint = psc
      movieView.addConstraint(psc)
    }
  }
  
  private static func timeString(_ time: CMTime, withTenths: Bool) -> String {
    let secondsTimes10: Int64 = Int64(CMTimeGetSeconds(time) * 10)
    let t = secondsTimes10 % 10
    let seconds = secondsTimes10 / 10
    let ss = seconds % 60
    let minutes = seconds / 60
    let mm = minutes % 60
    let hh = minutes / 60
    
    return withTenths ? String(format: "%02d:%02d:%02d.%d", hh, mm, ss, t) :
      String(format: "%02d:%02d:%02d", hh, mm, ss)
  }

  private static func timeFromString(_ str: String) -> CMTime? {
    let s = (str.characters.count == 8) ? (str + ".0") : str
    if s.characters.count == 10 {
      let fields = s.components(separatedBy: CharacterSet(charactersIn: ":."))
      if fields.count == 4 {
        let hh = Int64(fields[0]) ?? 0
        let mm = Int64(fields[1]) ?? 0
        let ss = Int64(fields[2]) ?? 0
        let t = Int64(fields[3]) ?? 0
        let value = (((((hh * 60) + mm) * 60) + ss) * 10) + t
        return CMTimeMake(value, 10)
      }
    }
    return nil
  }
  
  //
  // CanBorrowViewForFullScreen
  //
  
  public func getFullScreenHideableWindow() -> NSWindow? {
    return window
  }
  
  public func borrowViewForFullScreen() -> NSView? {
    oldResizingMask = view?.autoresizingMask ?? []
    return view
  }
  
  public func restoreViewFromFullScreen() {
    if let v = view {
      stackView.addView(v, in: .center)
    }
  }
  
  //
  // NSWindowController
  //
  
  override public var windowNibName: String? {
    get {
      return "MediaPanel"
    }
  }
  
  override public func windowDidLoad() {
    (window as? NSPanel)?.becomesKeyOnlyIfNeeded = true
    updateTitle()
    if view == nil {
      Bundle.main.loadNibNamed("MediaDetailsView", owner: self, topLevelObjects: nil)
      if let v = view {
        stackView.addView(v, in: .center)
      }
    }
  }
  
  override public func windowTitle(forDocumentDisplayName displayName: String) -> String {
    return displayName
  }
  
  //
  // NSMenuValidation
  //
  
  override public func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
    if menuItem.action == #selector(togglePlay(_:)) {
      let name = isPlaying ? "Pause" : "Play"
      menuItem.title = NSLocalizedString(name, comment: "")
      return (movie != nil)
    }
    else if menuItem.action == #selector(loadMedia(_:)) {
      return true
    }
    return false
  }
}

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

import AVFoundation
import AVKit
import Foundation

import HelperViews

@objc(MediaController)
public class MediaController: NSViewController {
  @IBOutlet private(set) var drawer: NSDrawer?
  @IBOutlet private(set) var fileNameLabel: NSTextField?
  @IBOutlet private(set) var movieView: AVPlayerView?
  @IBOutlet private(set) var stackingView: StackingView?
  @IBOutlet private(set) var movieDisclosureView: DisclosureView?
  @IBOutlet private(set) var propertiesDisclosureView: DisclosureView?
  @IBOutlet private(set) var totalTimeLabel: NSTextField?
  @IBOutlet private(set) var fileSizeLabel: NSTextField?
  @IBOutlet private(set) var timeCodeLabel: NSTextField?
  @IBOutlet private(set) var miniTimecodeView: MiniTimecodeView?
  
  private var _movie: AVAsset?
  private var player: AVPlayer?
  private var timer: Timer?
  private var movieFilePath: String?
  private var hasVideo: Bool = false
  private var lastTimeValue: CMTimeValue = 0
  
  required public init?(coder: NSCoder) {
    super.init(coder: coder)
    Bundle.main.loadNibNamed("MediaDrawerView", owner: self, topLevelObjects: nil)
  }

  deinit {
    NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NSViewFrameDidChange, object: movieDisclosureView)
    timer?.invalidate()
  }
  
  override public func awakeFromNib() {
    if let d = drawer {
      if drawer?.contentView != self.view {
        let size = self.view.frame.size
        self.view.autoresizesSubviews = true
        d.contentSize = size
        d.minContentSize = size
        d.contentView = self.view
      }
    }
    showMovieFileName()
    movieDisclosureView?.isHidden = true
    propertiesDisclosureView?.isHidden = true
    miniTimecodeView?.isHidden = true
    
    NotificationCenter.default.addObserver(self, selector: #selector(viewResized), name: NSNotification.Name.NSViewFrameDidChange, object: movieDisclosureView)
    
    if timer == nil {
      let t = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(timerTask), userInfo: nil, repeats: true)
      timer = t
      RunLoop.current.add(t, forMode: RunLoopMode.defaultRunLoopMode)
    }
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
          movieView?.player = player
          hasVideo = actualMovie.tracks(withMediaCharacteristic: AVMediaCharacteristicVisual).count > 0
          movieDisclosureView?.title = NSLocalizedString(hasVideo ? "Video" : "AudioOnly", comment: "")
          movieDisclosureView?.isHidden = false
          updateMovieViewSize()
          
          totalTimeLabel?.stringValue = MediaController.timeString(actualMovie.duration, withTenths: false)
          
          propertiesDisclosureView?.isHidden = false
          miniTimecodeView?.isHidden = false
          
          lastTimeValue = -1
        }
        else {
          player = nil
          movieDisclosureView?.isHidden = true
          propertiesDisclosureView?.isHidden = true
          timeCodeLabel?.stringValue = ""
          miniTimecodeView?.timeCodeString = ""
          miniTimecodeView?.isHidden = true
        }
      }
    }
  }
  
  public var mediaFilePath: String? {
    get {
      return movieFilePath
    }
  }
  
  @IBAction public func loadMedia(_ sender: Any?) {
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
    if movieFilePath == filePath {
      return
    }
    let m = AVURLAsset(url: NSURL.fileURL(withPath: filePath))
    
    movieFilePath = filePath
    showMovieFileName()
    self.movie = m
    
    let attrs = try FileManager.default.attributesOfItem(atPath: filePath)
    let fileSize = (attrs[FileAttributeKey.size] as? NSNumber)?.int64Value ?? 0
    fileSizeLabel?.stringValue =
      ByteCountFormatter.string(fromByteCount: fileSize,
                                countStyle: ByteCountFormatter.CountStyle.file)
  }
  
  public func closeMediaFile() {
    if self.movie != nil {
      self.movie = nil
      movieFilePath = nil
    }
  }

  private func showMovieFileName() {
    if let p = movieFilePath {
      fileNameLabel?.stringValue = ((p as NSString).lastPathComponent as NSString).deletingPathExtension
    }
    else {
      fileNameLabel?.stringValue = NSLocalizedString("NoMediaFile", comment: "")
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
  
  public func lendViewsToStackingView(_ sv: StackingView) {
    sv.addSubview(miniTimecodeView!)
    movieDisclosureView?.removeFromSuperview()
    sv.addSubview(movieDisclosureView!)
    propertiesDisclosureView?.removeFromSuperview()
    sv.addSubview(propertiesDisclosureView!)
  }

  public func restoreViews() {
    miniTimecodeView?.removeFromSuperview()
    movieDisclosureView?.removeFromSuperview()
    stackingView?.addSubview(movieDisclosureView!)
    propertiesDisclosureView?.removeFromSuperview()
    stackingView?.addSubview(propertiesDisclosureView!)
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
  
  //
  // internal use
  //
  
  func timerTask(_ sender: Any) {
    updateTimeCode()
  }

  func updateTimeCode() {
    if let p = player {
      let current = p.currentTime()
      if current.value != lastTimeValue {
        lastTimeValue = current.value
        let ts = MediaController.timeString(current, withTenths: true)
        timeCodeLabel?.stringValue = ts
        miniTimecodeView?.timeCodeString = ts
      }
    }
  }

  private func updateMovieViewSize() {
    if (hasVideo) {
      if let m = movie {
        if let track = m.tracks(withMediaType: AVMediaTypeVideo).first {
          let size = track.naturalSize
          let moviePanelHeight = ((movieDisclosureView?.frame.size.width ?? 0) * size.height) / size.width
          movieDisclosureView?.preferredHeight = moviePanelHeight
        }
      }
    }
    else {
      // With AVPlayerView, unlike QTMovieView, there doesn't seem to be any way to get the height of
      // just the controller bar.  So we're getting the minimum height of the overall view instead,
      // which includes the big useless "Quicktime audio" logo; oh well.
      movieDisclosureView?.preferredHeight = movieView?.fittingSize.height ?? 0
    }
  }
  
  @IBAction private func viewResized(_ sender: Any) {
    updateMovieViewSize()
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
}


@objc(MiniTimecodeView)
public class MiniTimecodeView: NSView, ViewSizeLimits {
  @IBOutlet private(set) var timeCodeLabel: NSTextField?
  public var timeCodeString: String? {
    get {
      return timeCodeLabel?.stringValue
    }
    set(s) {
      timeCodeLabel?.stringValue = s ?? ""
    }
  }
  private var minSize: NSSize = NSMakeSize(0, 0)
  
  required public init?(coder: NSCoder) {
    super.init(coder: coder)
  }
  
  override init(frame r: NSRect) {
    super.init(frame: r)
  }
  
  override public func awakeFromNib() {
    minSize = frame.size
  }
  
  public func minimumSize() -> NSSize {
    return minSize
  }
  
  public func maximumSize() -> NSSize {
    return minSize
  }
}

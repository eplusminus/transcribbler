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

import Media

@objc(DocPreferences)
public class DocPreferences: NSObject {
  
  static let windowPosKey = "WindowPos"
  static let mediaFilePathKey = "MediaFile"
  static let timeCodeKey = "TimeCode"
  static let timeCodeOffsetSubtractKey = "TimeCodeOffsetSubtract"
  static let timeCodeOffsetAddKey = "TimeCodeOffsetAdd"
  static let playbackRatePercentKey = "PlaybackRatePercent"
  
  public var windowPos: NSRect?
  public var mediaFilePath: String?
  public var timeCodeString: String?
  public var timeCodeOffsetSubtract: TimeWrapper?
  public var timeCodeOffsetAdd: TimeWrapper?
  public var playbackRatePercent: Int?
  
  public func serializeToStrings() -> [String: String] {
    var d: [String: String] = [:]
    
    d[DocPreferences.windowPosKey] = windowPos.map { NSStringFromRect($0) }
    d[DocPreferences.mediaFilePathKey] = mediaFilePath
    d[DocPreferences.timeCodeKey] = timeCodeString
    d[DocPreferences.timeCodeOffsetSubtractKey] = timeCodeOffsetSubtract.map {
      MediaController.timeString($0.value, withFractions: true) }
    d[DocPreferences.timeCodeOffsetAddKey] = timeCodeOffsetAdd.map {
      MediaController.timeString($0.value, withFractions: true) }
    d[DocPreferences.playbackRatePercentKey] = playbackRatePercent.map { String($0) }
    
    return d
  }
  
  public static func deserializeFromStrings(_ dict: [String: String]) -> DocPreferences {
    let p = DocPreferences()
    
    p.windowPos = dict[windowPosKey].flatMap {
      let r = NSRectFromString($0)
      return (r.size.width > 0) ? r : nil
    }
    p.mediaFilePath = dict[mediaFilePathKey]
    p.timeCodeString = dict[timeCodeKey]
    p.timeCodeOffsetSubtract = dict[timeCodeOffsetSubtractKey].flatMap {
      MediaController.timeFromString($0) }.map { TimeWrapper($0) }
    p.timeCodeOffsetAdd = dict[timeCodeOffsetAddKey].flatMap {
      MediaController.timeFromString($0) }.map { TimeWrapper($0) }
    p.playbackRatePercent = dict[playbackRatePercentKey].flatMap { Int($0) }
    
    return p
  }
}

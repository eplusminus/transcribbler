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

import AVFoundation
import Foundation

@objc(AppPreferences)
public class AppPreferences: NSObject {

  private static var sInstance: AppPreferences? = nil;
  
  public static var sharedInstance: AppPreferences {
    get {
      if let i = sInstance {
        return i
      }
      let ni = AppPreferences()
      sInstance = ni
      return ni
    }
  }
  
  public var replayIntervalPercent: Int = 100
  
  private static var ReplayIntervalPercentKey = "ReplayIntervalPercent"
  
  public func loadPreferences() {
    replayIntervalPercent = UserDefaults.standard.integer(forKey: AppPreferences.ReplayIntervalPercentKey)
    apply()
  }
  
  public func savePreferences() {
    apply()
    UserDefaults.standard.set(replayIntervalPercent, forKey: AppPreferences.ReplayIntervalPercentKey)
  }
  
  private func apply() {
    MediaController.replayInterval = CMTimeMake(Int64(replayIntervalPercent), 100)
  }
}

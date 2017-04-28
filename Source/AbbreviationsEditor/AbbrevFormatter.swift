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

import Abbreviations
import Foundation

@objc(AbbrevFormatter)
public class AbbrevFormatter: Formatter {
  override public func string(for obj: Any?) -> String? {
    if let o = obj {
      return o as? String
    }
    return nil;
  }
  
  override public func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, errorDescription: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
    if let o = obj {
      o.pointee = ((filterString(string) ?? string) as AnyObject)
    }
    return true
  }
  
  override public func isPartialStringValid(_ partialString: String,
                                            newEditingString: AutoreleasingUnsafeMutablePointer<NSString?>?,
                                            errorDescription: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
    if let f = filterString(partialString) {
      if let n = newEditingString {
        n.pointee = (f as NSString)
      }
      return false
    }
    return true
  }
  
  func filterString(_ s: String) -> String? {
    let buf = NSMutableString()
    let ap = AbbrevParser.sharedInstance()
    var filtered = false
    var i = s.characters.startIndex
    while i < s.characters.endIndex {
      if ap.isWordTerminator(s.characters[i]) {
        if !filtered {
          filtered = true
          buf.append(s.substring(to: i))
        }
      }
      else {
        if (filtered) {
          buf.append(s.substring(with: i..<(s.index(after:i))))
        }
      }
      i = s.index(after: i)
    }
    return filtered ? (buf as String) : nil
  }
}

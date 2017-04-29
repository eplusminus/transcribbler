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

import Foundation


let paramFieldStart = "{$$"
let paramFieldEnd = "$$}"
let paramFieldDelim = "="

// A super simple formatter for embedding key-value pairs in a string (which we'll be
// storing in a RTF document comment).
@objc class CommentStringFields: NSObject {
  public class func stringFromParams(_ params: [String: String]) -> String {
    var buf = String()
    for (name, value) in params {
      buf += paramFieldStart
      buf += name
      buf += paramFieldDelim
      buf += value
      buf += paramFieldEnd
    }
    return buf
  }
  
  public class func paramsFromString(_ str: String) -> ([String: String], String) {
    var params: [String: String] = [:]
    var leftoverBuf = ""
    let scan = Scanner(string: str)
    scan.charactersToBeSkipped = nil
    let fieldDelim = CharacterSet(charactersIn: paramFieldDelim)
    while !scan.isAtEnd {
      var s: NSString?
      if scan.scanUpTo(paramFieldStart, into: &s) {
        leftoverBuf += ((s ?? "") as String)
      }
      if scan.scanString(paramFieldStart, into: nil) {
        var name: NSString?
        if scan.scanUpToCharacters(from: fieldDelim, into: &name) &&
           scan.scanCharacters(from: fieldDelim, into: nil) {
          var value: NSString?
          scan.scanUpTo(paramFieldEnd, into: &value)
          if scan.scanString(paramFieldEnd, into: nil) {
            params[(name ?? "") as String] = (value ?? "") as String
          }
        }
      }
    }
    return (params, leftoverBuf)
  }
}

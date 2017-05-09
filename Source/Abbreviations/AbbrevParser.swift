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

var sAbbrevParser: AbbrevParser? = nil

public class AbbrevParser: NSObject {
  private var wordTerminators: CharacterSet = CharacterSet(charactersIn: " \r\n\t,.-!?'\"")
  private var nonTerminatorsInsideWord: CharacterSet = CharacterSet(charactersIn: "'")
  
  public class func sharedInstance() -> AbbrevParser {
    if let p = sAbbrevParser {
      return p
    }
    let np = AbbrevParser()
    sAbbrevParser = np
    return np
  }
  
  private static func charInSet(_ ch: Character, _ cs: CharacterSet) -> Bool {
    if let uc = String(ch).unicodeScalars.first {
      return cs.contains(uc)
    }
    return false
  }
  
  public func isWordTerminator(_ char: unichar) -> Bool {
    return wordTerminators.contains(UnicodeScalar(char)!)
  }
  
  public func isWordTerminator(_ char: Character) -> Bool {
    return AbbrevParser.charInSet(char, wordTerminators)
  }

  public func findPossibleAbbreviation(inString: String, beforePos: Int) -> String? {
    let before = inString.index(inString.startIndex, offsetBy: beforePos)
    if before == inString.startIndex {
      return nil
    }
    var start = before
    repeat {
      start = inString.index(before: start)
      let ch = inString[start]
      if AbbrevParser.charInSet(ch, wordTerminators) {
        // The following test is meant to keep us from expanding things like the
        // "s" in "that's"; the apostrophe counts as a boundary character for
        // terminating words (so the "that" could be expanded), and it counts as one
        // if it's preceded by another terminator (e.g. a space), but not if it's
        // inside an existing word.
        if AbbrevParser.charInSet(ch, nonTerminatorsInsideWord) {
          if start > inString.startIndex {
            if !AbbrevParser.charInSet(inString[inString.index(before: start)], wordTerminators) {
              continue
            }
          }
        }
        start = inString.index(after: start)
        break
      }
    } while start != inString.startIndex
    return inString.substring(with: (start..<before))
  }
  
  public func renderExpansion(_ expansion: String, abbreviation: String) -> String {
    if !(abbreviation == abbreviation.lowercased()) {
      // If the whole short form is uppercase, return all uppercase
      if ((abbreviation.characters.count > 1) && (abbreviation == abbreviation.uppercased())) {
        return expansion.uppercased()
      }
      // If the first letter is uppercase, return first letter uppercase
      let first = String(abbreviation.characters.prefix(1))
      if (first == first.uppercased()) {
        return String(expansion.characters.prefix(1)).uppercased() + String(expansion.characters.dropFirst())
      }
    }
    return expansion
  }
}

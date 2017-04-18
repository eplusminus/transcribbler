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

import Foundation

@objc(AbbrevEntry)
class AbbrevEntry: AbbrevBase {
  var variants: [AbbrevBase]? = nil
  
  public init() {
    super.init(abbreviation: "", expansion: "")
  }
  
  func expansionDesc() -> String {
    if let vs = variants {
      let s = NSMutableString(capacity: 100)
      s.append(expansion)
      if vs.count > 0 {
        s.append("~")
        for v in vs {
          s.append(v.abbreviation)
          if !(v.expansion == v.abbreviation) {
            s.append("=")
            s.append(v.expansion)
          }
          s.append(" ")
        }
      }
      return s as String
    }
    else {
      return expansion
      
    }
  }
  
  func setExpansionDesc(_ desc: String) {
    let scan = Scanner(string: desc)
    scan.charactersToBeSkipped = nil
    expansion = ""
    var s: NSString?
    if scan.scanUpTo("~", into: &s) {
      if let ss = s {
        expansion = ss as String
      }
    }
    if !scan.scanString("~", into: nil) {
      variants = nil
    }
    else {
      var vv = [AbbrevBase]() /* capacity: 2 */
      let nameDelims = CharacterSet(charactersIn: " \t=")
      while scan.scanUpToCharacters(from: nameDelims, into: &s) {
        if let ss = s {
          var x: NSString = ss
          var xo: NSString?
          if scan.scanString("=", into: nil) {
            scan.scanUpToCharacters(from: CharacterSet.whitespaces, into: &xo)
            if let xx = xo {
              x = xx
            }
          }
          if ss.length > 0 {
            let v = AbbrevBase(abbreviation: ss as String, expansion: x as String)
            vv.append(v)
          }
        }
        scan.scanCharacters(from: CharacterSet.whitespaces, into: nil)
      }
      variants = vv
    }
  }
  
  func variantAbbreviation(_ variant: AbbrevBase) -> String {
    return abbreviation + variant.abbreviation
  }
  
  func variantExpansion(_ variant: AbbrevBase) -> String {
    let se: String = expansion
    let ve: String = variant.expansion
    if (ve == "") {
      return se
    }
    let prefix: Character = ve[ve.startIndex]
    if (prefix != "<") && (prefix != ">") {
      return se + (ve)
    }
    var origLength = se.endIndex
    var addLength = ve.index(before: ve.endIndex)
    if prefix == "<" {
      if origLength > se.startIndex {
        origLength = se.index(before: origLength)
      }
    }
    else if prefix == ">" {
      if origLength > se.startIndex {
        addLength = ve.index(after: addLength)
      }
    }
    var s = se.substring(to: origLength)
    if prefix == ">" {
      s += String(se[se.index(before: origLength)])
    }
    s += ve.substring(from: ve.index(after: ve.startIndex))
    return s
  }
  
  func isEmpty() -> Bool {
    return (abbreviation == "") && (expansion == "")
  }
  
  //
  //	NSCoding methods
  //
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    if (coder.containsValue(forKey: "var")) {
      variants = coder.decodeObject(forKey: "var") as! [AbbrevBase]
    }
  }
  
  override func encode(with: NSCoder) {
    super.encode(with: with)
    if let vs = variants {
      with.encode(vs, forKey: "var")
    }
  }
}

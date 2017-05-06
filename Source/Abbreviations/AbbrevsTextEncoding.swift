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

public class AbbrevsTextEncoding: AbbrevsEncoding {
  public init() {
  }
  
  public func pasteboardType() -> String {
    return NSPasteboardTypeString
  }
  
  public func readAbbrevsFromData(_ data: Data) throws -> [AbbrevEntry] {
    var aa = [AbbrevEntry]()
    if let s = String(data: data, encoding: String.Encoding.utf8) {
      let scan = Scanner(string: s)
      while !scan.isAtEnd {
        scan.scanCharacters(from: CharacterSet.whitespacesAndNewlines, into: nil)
        var n: NSString?
        if scan.scanUpToCharacters(from: CharacterSet.whitespacesAndNewlines, into: &n) {
          var v: NSString?
          if scan.scanUpToCharacters(from: CharacterSet.newlines, into: &v) {
            let (ex, vs) = AbbrevsTextEncoding.parseExpansionAndVariants((v ?? "") as String)
            let a = AbbrevEntry(abbreviation: (n ?? "") as String, expansion: ex, variants: vs)
            aa.append(a)
          }
        }
      }
    }
    return aa
  }
  
  public func writeAbbrevsToData(_ abbrevs: [AbbrevEntry]) -> Data {
    let textBuffer = NSMutableString(capacity: 2000)
    for a in abbrevs {
      if !a.isEmpty() {
        textBuffer.append(a.abbreviation)
        textBuffer.append("\t")
        textBuffer.append(AbbrevsTextEncoding.formatExpansion(a.expansion, a.variants))
        textBuffer.append("\n")
      }
    }
    return textBuffer.data(using: String.Encoding.utf8.rawValue)!
  }
  
  public class func formatExpansion(_ expansion: String, _ variants: [AbbrevBase]?) -> String {
    if let vs = variants {
      let s = NSMutableString(capacity: 100)
      s.append(expansion)
      var first: Bool = true
      if vs.count > 0 {
        for v in vs {
          s.append(first ? "~" : " ")
          first = false
          s.append(v.abbreviation)
          if !(v.expansion == v.abbreviation) {
            s.append("=")
            s.append(v.expansion)
          }
        }
      }
      return s as String
    }
    else {
      return expansion
    }
  }
  
  public class func parseExpansionAndVariants(_ desc: String) -> (String, [AbbrevBase]?) {
    var expansion = ""
    var variants: [AbbrevBase]? = nil
    
    let scan = Scanner(string: desc)
    scan.charactersToBeSkipped = nil
    var s: NSString?
    if scan.scanUpTo("~", into: &s) {
      if let ss = s {
        expansion = ss as String
      }
    }
    if scan.scanString("~", into: nil) {
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
    
    return (expansion, variants)
  }
}

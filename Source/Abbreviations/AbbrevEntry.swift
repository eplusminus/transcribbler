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

@objc(AbbrevEntry)
public class AbbrevEntry: AbbrevBase {
  public var variants: [AbbrevBase]? = nil
  
  override public init() {
    super.init(abbreviation: "", expansion: "")
  }
  
  override public init(abbreviation: String, expansion: String) {
    super.init(abbreviation: abbreviation, expansion: expansion)
  }

  public var hasVariants: Bool {
    get {
      return (variants?.count ?? 0) > 0
    }
  }
  
  public func variantAbbreviation(_ variant: AbbrevBase) -> String {
    return abbreviation + variant.abbreviation
  }
  
  public func variantExpansion(_ variant: AbbrevBase) -> String {
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
  
  //
  //	NSCoding methods
  //
  
  required public init?(coder: NSCoder) {
    super.init(coder: coder)
    if (coder.containsValue(forKey: "var")) {
      variants = coder.decodeObject(forKey: "var") as? [AbbrevBase]
    }
  }
  
  override public func encode(with: NSCoder) {
    super.encode(with: with)
    if let vs = variants {
      with.encode(vs, forKey: "var")
    }
  }
}

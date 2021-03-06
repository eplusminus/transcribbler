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

@objc(AbbrevBase)
public class AbbrevBase: NSObject, NSCoding {
  public var abbreviation: String = ""
  public var expansion: String = ""
  
  override public init() {
    super.init()
  }
  
  public init(abbreviation: String, expansion: String) {
    self.abbreviation = abbreviation
    self.expansion = expansion
  }
  
  public func isEmpty() -> Bool {
    return (abbreviation == "") && (expansion == "")
  }

  override public func isEqual(_ object: Any?) -> Bool {
    guard let other = object as? AbbrevBase else { return false }
    return self.abbreviation == other.abbreviation && self.expansion == other.expansion
  }
  
  //
  //	NSCoding methods
  //

  required public init?(coder aDecoder: NSCoder) {
    self.abbreviation = (aDecoder.decodeObject(forKey: "short") as? String) ?? ""
    self.expansion = (aDecoder.decodeObject(forKey: "long") as? String) ?? ""
    // TODO: do we still need behavior of refusing to decode something with empty fields?
  }

  public func encode(with: NSCoder) {
    with.encode(self.abbreviation, forKey: "short")
    with.encode(self.expansion, forKey: "long")
  }
}

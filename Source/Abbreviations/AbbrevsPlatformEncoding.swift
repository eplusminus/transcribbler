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

public class AbbrevsPlatformEncoding: AbbrevsEncoding {
  public init() {
  }
  
  public func pasteboardType() -> String {
    return "net.errorbar.transcribber.table"
  }
  
  public func readAbbrevsFromData(_ data: Data) throws -> [AbbrevEntry] {
    return (NSKeyedUnarchiver.unarchiveObject(with: data) as? [AbbrevEntry]) ?? ([AbbrevEntry]())
  }
  
  public func writeAbbrevsToData(_ abbrevs: [AbbrevEntry]) -> Data {
    return NSKeyedArchiver.archivedData(withRootObject: abbrevs)
  }
}

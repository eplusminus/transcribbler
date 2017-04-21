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

let AbbreviationsPasteboardType = "AbbreviationsPasteBoardType"
let DefaultAbbrevsKey = "DefaultAbbrevations"


@objc(AbbrevArrayController)
class AbbrevArrayController: NSArrayController {
  @IBOutlet private(set) var document: AbbrevListDocument!
  
  class func pasteboardType() -> String {
    return AbbreviationsPasteboardType
  }
  
  override func awakeFromNib() {
    let data: Data? = UserDefaults.standard.data(forKey: DefaultAbbrevsKey)
    if data != nil {
      if let es = NSKeyedUnarchiver.unarchiveObject(with: data!) as? [Any] {
        add(contentsOf: es)
      }
      self.setSelectionIndexes(IndexSet())
      document.modified()
    }
  }

  @IBAction func delete(_ sender: Any) {
    if selectionIndex != NSNotFound {
      remove(contentsOf: selectedObjects)
      persist()
    }
  }
  
  override func add(_ sender: Any?) {
    super.add(sender)
    persist()
  }
  
  override func remove(_ sender: Any?) {
    super.remove(sender)
    persist()
  }

  @IBAction func copy(_ sender: Any) {
    let selectedObjects: [Any] = self.selectedObjects
    let count: Int = selectedObjects.count
    if count == 0 {
      return
    }
    var copyObjectsArray = [Any]() /* capacity: count */
    let textBuffer = NSMutableString(capacity: 2000)
    if let sos = selectedObjects as? [AbbrevEntry] {
      for a in sos {
        copyObjectsArray.append(a)
        if !a.isEmpty() {
          textBuffer.append(a.abbreviation)
          textBuffer.append("\t")
          textBuffer.append(a.expansion)
          textBuffer.append("\n")
        }
      }
    }
 
    let pb = NSPasteboard.general()
    pb.declareTypes([AbbreviationsPasteboardType, NSPasteboardTypeString], owner: self)
    let copyData = NSKeyedArchiver.archivedData(withRootObject: copyObjectsArray)
    pb.setData(copyData, forType: AbbreviationsPasteboardType)
    pb.setString(textBuffer as String, forType: NSPasteboardTypeString)
  }
  
  @IBAction func paste(_ sender: Any) {
    let pb = NSPasteboard.general()
    let data: Data? = pb.data(forType: AbbreviationsPasteboardType)
    var items: [Any] = [Any]()
    if data != nil {
      items = (NSKeyedUnarchiver.unarchiveObject(with: data!) as? [Any]) ?? ([Any]())
    }
    else {
      if let s: String = pb.string(forType: NSPasteboardTypeString) {
        let scan = Scanner(string: s)
        var aa = [Any]()
        while !scan.isAtEnd {
          scan.scanCharacters(from: CharacterSet.whitespacesAndNewlines, into: nil)
          var n: NSString?
          if scan.scanUpToCharacters(from: CharacterSet.whitespacesAndNewlines, into: &n) {
            var v: NSString?
            if scan.scanUpToCharacters(from: CharacterSet.newlines, into: &v) {
              let a: AbbrevEntry = newEntry()
              a.abbreviation = (n ?? "") as String
              let (ex, vs) = AbbrevSimpleFormat.parseExpansionAndVariants((v ?? "") as String)
              a.expansion = ex
              a.variants = vs
              aa.append(a)
            }
          }
        }
        items = aa
      }
    }
    
    if items.count > 0 {
      var pos: Int = selectionIndex
      if pos == NSNotFound {
        pos = (arrangedObjects as? [Any])?.count ?? 0
      }
      for a: AbbrevEntry in (items as? [AbbrevEntry]) ?? ([AbbrevEntry]()) {
        insert(a, atArrangedObjectIndex: pos)
        pos += 1
      }
      persist()
    }
  }
  
  override func objectDidEndEditing(_ editor: Any) {
    super.objectDidEndEditing(editor)
    persist()
  }
  
  func newEntry() -> AbbrevEntry {
    let e = AbbrevEntry()
    return e
  }
  
  func persist() {
    document.modified()
    let data = NSKeyedArchiver.archivedData(withRootObject: arrangedObjects)
    UserDefaults.standard.set(data, forKey: DefaultAbbrevsKey)
  }
}

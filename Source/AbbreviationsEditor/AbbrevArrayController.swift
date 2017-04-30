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

let DefaultAbbrevsKey = "DefaultAbbrevations"

let supportedEncodings: [AbbrevsEncoding] = [AbbrevsPlatformEncoding(), AbbrevsTextEncoding()]

@objc(AbbrevArrayController)
class AbbrevArrayController: NSArrayController {
  @IBOutlet private(set) var document: AbbrevListDocument!
  
  class func pasteboardTypes() -> [String] {
    return supportedEncodings.map { e in e.pasteboardType() }
  }
  
  override func awakeFromNib() {
    if let data = UserDefaults.standard.data(forKey: DefaultAbbrevsKey) {
      do {
        let es = try AbbrevsPlatformEncoding().readAbbrevsFromData(data)
        add(contentsOf: es)
        self.setSelectionIndexes(IndexSet())
        document.modified()
      }
      catch {
      }
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
    let selectedEntries: [AbbrevEntry] = (self.selectedObjects as? [AbbrevEntry]) ?? []
    if selectedEntries.count == 0 {
      return
    }
    
    let pb = NSPasteboard.general()
    pb.declareTypes(AbbrevArrayController.pasteboardTypes(), owner: self)
    for e in supportedEncodings {
      if let data = e.writeAbbrevsToData(selectedEntries) {
        pb.setData(data, forType: e.pasteboardType())
      }
    }
  }
  
  @IBAction func paste(_ sender: Any) {
    let pb = NSPasteboard.general()
    var items: [Any] = [Any]()
    
    for e in supportedEncodings {
      if let data = pb.data(forType: e.pasteboardType()) {
        do {
          try items = e.readAbbrevsFromData(data)
        }
        catch {
        }
        break
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
  
  public func newEntry() -> AbbrevEntry {
    let e = AbbrevEntry()
    return e
  }
  
  func persist() {
    document.modified()
    if let es = arrangedObjects as? [AbbrevEntry] {
      if let data = AbbrevsPlatformEncoding().writeAbbrevsToData(es) {
        UserDefaults.standard.set(data, forKey: DefaultAbbrevsKey)
      }
    }
  }
}

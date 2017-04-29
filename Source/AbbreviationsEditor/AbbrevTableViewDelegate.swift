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
import HelperViews

@objc(AbbrevTableViewDelegate)
public class AbbrevTableViewDelegate: NSResponder, NSTableViewDelegate, HandyTableViewDelegate {
  @IBOutlet private(set) var table: AbbrevArrayController!
  @IBOutlet private(set) var view: NSTableView!
  
  var resolver: AbbrevResolver? = nil
  
  func entryAtIndex(_ i: Int) -> AbbrevEntry? {
    if i >= 0 {
      let os = table.arrangedObjects as! [AnyObject]
      if i < os.count {
        return os[i] as? AbbrevEntry
      }
    }
    return nil
  }
  
  override public func awakeFromNib() {
    self.nextResponder = view.nextResponder
    view.nextResponder = self
  }

  @IBAction public func delete(_ sender: Any) {
    table.delete(self)
  }

  @IBAction public func cut(_ sender: Any) {
    table.copy(self)
    table.delete(self)
  }

  @IBAction public func copy(_ sender: Any) {
    table.copy(self)
  }

  @IBAction public func paste(_ sender: Any) {
    table.paste(self)
  }
  
  public func tableView(_ aTableView: NSTableView, willDisplayCell aCell: Any, for aTableColumn: NSTableColumn?, row: Int) {
    var dup = false
    if let a = entryAtIndex(row) {
      if let r = resolver {
        if aTableColumn?.identifier == "abbreviation" && r.hasDuplicateAbbreviation(a) {
          dup = true
        }
      }
    }
    let cell = aCell as! NSTextFieldCell
    cell.backgroundColor = dup ? NSColor.yellow : NSColor.textBackgroundColor
    cell.textColor = dup ? NSColor.red : nil
    cell.drawsBackground = dup
  }
  
  @IBAction public func newAbbreviation(_ sender: Any) {
    self.add(sender)
  }

  @IBAction public func add(_ sender: Any?) {
    var row = view.selectedRow
    if row < 0 {
      row = view.numberOfRows
    }
    else {
      let e = entryAtIndex(row)
      if e == nil {
        view.editColumn(0, row: row, with: nil, select: false)
        return;
      }
      row += 1
    }
    table.insert(table.newEntry(), atArrangedObjectIndex: row)
    view.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
    view.editColumn(0, row: row, with: nil, select: false)
  }
  
  override public func keyDown(with event: NSEvent) {
    if let ch = event.characters?.unicodeScalars.first {
      let ci = Int(ch.value)
      if ci == NSDeleteCharacter || ci == NSDeleteFunctionKey {
        self.delete(self)
        return
      }
    }
    super.keyDown(with: event)
  }

  public func validateUserInterfaceItem(item: NSValidatedUserInterfaceItem) -> Bool {
    if let theAction = item.action {
      if theAction == #selector(copy(_:)) || theAction == #selector(cut) || theAction == #selector(delete) {
        return (table.selectionIndex != NSNotFound)
      }
      
      if theAction == #selector(paste) {
        let pb = NSPasteboard.general()
        return (pb.data(forType: AbbrevArrayController.pasteboardType()) != nil)
      }
    }
    return false
  }
  
  //
  // HandyTableViewDelegate
  //
  public func tableViewCanDeleteEmptyRow(_ v: HandyTableView, row: NSInteger) -> Bool {
    return entryAtIndex(row)?.isEmpty() ?? false
  }
  
  public func tableViewClickedBelowLastRow(_ v: HandyTableView, point: NSPoint) -> Bool {
    v.validateEditing()
    v.abortEditing()
    
    let count = v.numberOfRows
    if count > 0 {
      if entryAtIndex(count - 1)?.isEmpty() ?? false {
        v.selectRowIndexes(IndexSet(integer: count - 1), byExtendingSelection: false)
        v.editColumn(0, row: count - 1, with: nil, select: false)
        return true
      }
    }
    v.selectRowIndexes(IndexSet(), byExtendingSelection: false)
    self.add(nil)
    return true
  }
}

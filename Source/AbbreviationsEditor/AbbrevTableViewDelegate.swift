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
import HelperViews

import Cocoa
import Foundation

let supportedEncodings: [AbbrevsEncoding] = [AbbrevsPlatformEncoding(), AbbrevsTextEncoding()]
let pasteboardTypes: [String] = supportedEncodings.map { e in e.pasteboardType() }

@objc(AbbrevTableViewDelegate)
public class AbbrevTableViewDelegate: NSResponder, NSTableViewDataSource, NSTableViewDelegate, HandyTableViewDelegate {
  @IBOutlet var table: NSArrayController?
  @IBOutlet private(set) var view: HandyTableView!
  @IBOutlet private(set) var statusColumn: NSTableColumn!
  @IBOutlet private(set) var abbreviationColumn: NSTableColumn!
  @IBOutlet private(set) var expansionColumn: NSTableColumn!
  
  var resolver: AbbrevResolver? = nil
  private var errorImage: NSImage?
  private var suffixImage: NSImage?
  
  func entryAtIndex(_ i: Int) -> AbbrevEntry? {
    if let t = table {
      if i >= 0 {
        let os = t.arrangedObjects as! [AnyObject]
        if i < os.count {
          return os[i] as? AbbrevEntry
        }
      }
    }
    return nil
  }
  
  func replaceEntryAtIndex(_ i: Int, _ e: AbbrevEntry) {
    table?.remove(atArrangedObjectIndex: i)
    table?.insert(e, atArrangedObjectIndex: i)
  }
  
  override public func awakeFromNib() {
    self.nextResponder = view.nextResponder
    view.nextResponder = self
    errorImage = NSImage(named: "ErrorFlag")
    suffixImage = NSImage(named: "SuffixFlag")
  }
  
  @IBAction public func newAbbreviation(_ sender: AnyObject?) {
    self.add(sender)
  }
  
  @IBAction public func removeAbbreviation(_ sender: AnyObject?) {
    view.delete(sender)
  }
  
  @IBAction public func add(_ sender: AnyObject?) {
    var row = view.selectedRow
    let col = view.column(withIdentifier: abbreviationColumn.identifier)
    let max = view.numberOfRows
    if row < 0 {
      row = max
    }
    else {
      let e = entryAtIndex(row)
      if e == nil {
        view.editColumn(col, row: row, with: nil, select: false)
        return;
      }
      row += 1
    }
    view.acceptEdits()
    table?.insert(AbbrevEntry(), atArrangedObjectIndex: row)
    view.beginUpdates()
    view.insertRows(at: IndexSet(integer: row), withAnimation: [])
    view.endUpdates()
    view.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
    view.scrollRowToVisible(row)
    view.editColumn(col, row: row, with: nil, select: false)
  }
  
  @IBAction public func cut(_ sender: AnyObject?) {
    copyInternal()
    view.delete(sender)
  }

  @IBAction public func copy(_ sender: AnyObject?) {
    copyInternal()
  }

  @IBAction public func paste(_ sender: AnyObject?) {
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
      view.acceptEdits()
      var pos: Int = view.selectedRow
      let startPos = pos
      if pos == NSNotFound {
        pos = (table?.arrangedObjects as? [Any])?.count ?? 0
      }
      for a: AbbrevEntry in (items as? [AbbrevEntry]) ?? ([AbbrevEntry]()) {
        table?.insert(a, atArrangedObjectIndex: pos)
        pos += 1
      }
      view.beginUpdates()
      view.insertRows(at: IndexSet(integersIn: startPos..<pos), withAnimation: [])
      view.endUpdates()
    }
  }
  
  private func copyInternal() {
    let sri = view.selectedRowIndexes
    if !sri.isEmpty {
      var selectedEntries = [AbbrevEntry]()
      for i in sri {
        if let e = entryAtIndex(i) {
          selectedEntries.append(e)
        }
      }
      let pb = NSPasteboard.general()
      pb.declareTypes(pasteboardTypes, owner: self)
      for e in supportedEncodings {
        let data = e.writeAbbrevsToData(selectedEntries)
        pb.setData(data, forType: e.pasteboardType())
      }
    }
  }
  
  //
  // NSTableViewDataSource
  //
  
  public func numberOfRows(in tableView: NSTableView) -> Int {
    if let t = table {
      return (t.arrangedObjects as! [AnyObject]).count
    }
    return 0
  }
  
  public func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
    if let a = entryAtIndex(row) {
      switch tableColumn! {
      case statusColumn:
        let dup = resolver?.hasDuplicateAbbreviation(a) ?? false
        let suff = a.hasVariants
        return suff ? suffixImage : (dup ? errorImage : nil)
      case abbreviationColumn:
        return a.abbreviation
      case expansionColumn:
        return AbbrevsTextEncoding.formatExpansion(a.expansion, a.variants)
      default:
          return nil
      }
    }
    return nil
  }
  
  public func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
    if let a = entryAtIndex(row) {
      var a1 = a
      switch tableColumn! {
      case abbreviationColumn:
        a1 = AbbrevEntry(abbreviation: (object as? String) ?? "", expansion: a1.expansion, variants: a1.variants)
        break
      case expansionColumn:
        let (ex, vs) = AbbrevsTextEncoding.parseExpansionAndVariants((object as? String) ?? "")
        a1 = AbbrevEntry(abbreviation: a.abbreviation, expansion: ex, variants: vs)
        break
      default:
        break;
      }
      if a1 != a {
        replaceEntryAtIndex(row, a1)
      }
    }
  }
  
  //
  // NSTableViewDelegate
  //
  
  public func tableView(_ aTableView: NSTableView, willDisplayCell aCell: Any, for aTableColumn: NSTableColumn?, row: Int) {
    var dup = false
    if let a = entryAtIndex(row) {
      if let r = resolver {
        dup = r.hasDuplicateAbbreviation(a)
      }
    }
    if aTableColumn != statusColumn {
      let cell = aCell as! NSTextFieldCell
      cell.backgroundColor = dup ? NSColor.yellow : NSColor.textBackgroundColor
      cell.textColor = dup ? NSColor.red : nil
      cell.drawsBackground = dup
    }
  }
  
  public func validateUserInterfaceItem(item: NSValidatedUserInterfaceItem) -> Bool {
    if let a = item.action {
      switch a {
      case #selector(copy(_:)),
           #selector(cut(_:)),
           #selector(paste(_:)):
        return (table?.selectionIndex != NSNotFound)
      case #selector(paste(_:)):
        let pb = NSPasteboard.general()
        return pasteboardTypes.contains { t in pb.data(forType: t) != nil }
      default:
        return false
      }
    }
    return false
  }
  
  //
  // HandyTableViewDelegate
  //
  
  public func tableViewInsertRow(_ v: HandyTableView, beforeRow: NSInteger) -> Bool {
    if beforeRow <= v.numberOfRows {
      table?.insert(AbbrevEntry(), atArrangedObjectIndex: beforeRow)
      view.beginUpdates()
      view.insertRows(at: IndexSet(integer: beforeRow), withAnimation: [])
      view.endUpdates()
      return true
    }
    return false
  }
  
  public func tableViewDeleteRows(_ v: HandyTableView, rows: NSRange) -> Bool {
    table?.remove(atArrangedObjectIndexes: IndexSet(integersIn: rows.toRange()!))
    v.beginUpdates()
    v.removeRows(at: IndexSet(integersIn: rows.toRange()!), withAnimation: [])
    v.endUpdates()
    return true
  }
  
  public func tableViewRowIsEmpty(_ v: HandyTableView, row: NSInteger) -> Bool {
    return entryAtIndex(row)?.isEmpty() ?? false
  }
}

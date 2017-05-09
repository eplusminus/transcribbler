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

@objc(AbbrevSuffixEditor)
public class AbbrevSuffixEditor: NSViewController {
  @IBOutlet private(set) var editorPanelView: NSView!
  @IBOutlet private(set) var entryAbbreviationLabel: NSTextField!
  @IBOutlet private(set) var suffixTableView: NSTableView!
  @IBOutlet private(set) var suffixEditingTableData: AbbrevSuffixTableBehavior!
  @IBOutlet private(set) var commonSuffixesTableView: NSTableView!
  @IBOutlet private(set) var commonSuffixesTableData: AbbrevSuffixTableBehavior!

  public var popover: NSPopover = NSPopover()
  
  private var _abbrevEntry: AbbrevEntry? = nil

  override public init?(nibName: String?, bundle: Bundle?) {
    super.init(nibName: "AbbrevSuffixEditor", bundle: bundle)
    initPopover()
  }
  
  required public init?(coder aDecoder: NSCoder) {
    super.init(nibName: "AbbrevSuffixEditor", bundle: Bundle.main)
    initPopover()
  }

  private func initPopover() {
    popover.contentViewController = self
    popover.behavior = NSPopoverBehavior.transient
  }

  override public func viewDidLoad() {
    suffixEditingTableData.addObserver(self, forKeyPath: "variants", options: .new, context: nil)
  }
  
  public var isPopoverOpen: Bool {
    get {
      return popover.isShown
    }
  }
  
  public var abbrevEntry: AbbrevEntry? {
    get {
      return _abbrevEntry
    }
    set(e) {
      _abbrevEntry = e
      let _ = view  // triggers lazy loading
      entryAbbreviationLabel.stringValue = e?.abbreviation ?? ""
      suffixEditingTableData.baseEntry = e
      suffixEditingTableData.variants = e?.variants ?? []
      commonSuffixesTableData.baseEntry = e
      commonSuffixesTableData.variants = e.map { CommonSuffixes.suggestCommonSuffixesFor($0) } ?? []
      suffixTableView.reloadData()
      commonSuffixesTableView.reloadData()
    }
  }
  
  public var variants: [AbbrevBase] {
    get {
      return suffixEditingTableData.variants.filter { $0.abbreviation != "" }
    }
  }
  
  override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    if keyPath == "variants" {
      self.willChangeValue(forKey: "variants")
      self.didChangeValue(forKey: "variants")
    }
  }
  
  @IBAction public func clickedSuggestedSuffix(_ sender: AnyObject?) {
    let chosenPos = commonSuffixesTableView.selectedRow
    if chosenPos >= 0 {
      let chosenVariant = commonSuffixesTableData.variants[chosenPos]
      var pos: Int
      var insert: Bool
      if let i = suffixEditingTableData.variants.index(where: { $0.abbreviation == chosenVariant.abbreviation }) {
        insert = false
        pos = i
      }
      else {
        insert = true
        // pick a place to insert the new row corresponding to the order that the suggestion list is in
        if let firstOneOrderedAfterThis = suffixEditingTableData.variants.index(where: { v in
          if let foundPos = commonSuffixesTableData.variants.index(where: { $0.abbreviation == v.abbreviation }) {
            return foundPos > chosenPos
          }
          return false
        }) {
          pos = firstOneOrderedAfterThis
        }
        else {
          pos = suffixEditingTableData.variants.count
        }
      }
      suffixEditingTableData.addOrReplaceItemAt(chosenVariant, row: pos, insert: insert, tableView: suffixTableView)
    }
  }
}

@objc(AbbrevSuffixTableBehavior)
public class AbbrevSuffixTableBehavior: NSObject, NSTableViewDataSource, NSTableViewDelegate, HandyTableViewDelegate {
  public var baseEntry: AbbrevEntry? = nil
  public var variants: [AbbrevBase] = []
  @IBInspectable public var editable: Bool = false
  
  func addOrReplaceItemAt(_ variant: AbbrevBase, row: Int, insert: Bool, tableView: NSTableView) {
    self.willChangeValue(forKey: "variants")
    if insert {
      variants.insert(variant, at: row)
    }
    else {
      variants[row] = variant
    }
    self.didChangeValue(forKey: "variants")
    tableView.reloadData()
  }
  
  //
  // NSTableViewDataSource
  //
  
  public func numberOfRows(in tableView: NSTableView) -> Int {
    return variants.count
  }
  
  public func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
    if let colId = tableColumn?.identifier {
      if row >= 0 && row < variants.count {
        let v = variants[row]
        switch colId {
        case "short": return v.abbreviation
        case "long": return v.expansion
        case "result": return baseEntry?.variantExpansion(v)
        default: return nil
        }
      }
    }
    return nil
  }
  
  public func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
    if editable {
      if let colId = tableColumn?.identifier {
        if row >= 0 && row <= variants.count {
          let s = (object as? String) ?? ""
          let v0 = (row >= 0 && row < variants.count) ? variants[row] : AbbrevBase()
          var v1 = v0
          switch colId {
          case "short": v1 = AbbrevBase(abbreviation: s, expansion: v0.expansion)
          case "long": v1 = AbbrevBase(abbreviation: v0.abbreviation, expansion: s)
          default: break
          }
          if v1 !== v0 {
            self.willChangeValue(forKey: "variants")
            if row < variants.count {
              variants[row] = v1
            }
            else {
              variants.append(v1)
            }
            self.didChangeValue(forKey: "variants")
          }
        }
      }
    }
  }
  
  //
  // NSTableViewDelegate
  //
  
  public func tableView(_ tableView: NSTableView, shouldEdit tableColumn: NSTableColumn?, row: Int) -> Bool {
    return editable && !(tableColumn?.identifier == "result")
  }
  
  //
  // HandyTableViewDelegate
  //
  
  public func tableViewInsertRow(_ v: HandyTableView, beforeRow: NSInteger) -> Bool {
    if editable {
      if beforeRow <= v.numberOfRows {
        variants.insert(AbbrevBase(), at: beforeRow)
        v.beginUpdates()
        v.insertRows(at: IndexSet(integer: beforeRow), withAnimation: [])
        v.endUpdates()
        return true
      }
    }
    return false
  }
  
  public func tableViewRowIsEmpty(_ v: HandyTableView, row: NSInteger) -> Bool {
    return variants[row].isEmpty()
  }
}

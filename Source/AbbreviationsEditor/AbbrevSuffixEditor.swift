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
  @IBOutlet private(set) var suffixTableBehavior: AbbrevSuffixTableBehavior!
  
  public var popover: NSPopover = NSPopover()
  private var abbrevEntry: AbbrevEntry? = nil

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

  public var isPopoverOpen: Bool {
    get {
      return popover.isShown
    }
  }
  
  public func setAbbrevEntry(_ e: AbbrevEntry) {
    let _ = self.view  // ensures lazy loading has happened
    abbrevEntry = e
    entryAbbreviationLabel.stringValue = e.abbreviation
    suffixTableBehavior.abbrevEntry = e
    suffixTableView.reloadData()
  }
}

@objc(AbbrevSuffixTableBehavior)
public class AbbrevSuffixTableBehavior: NSObject, NSTableViewDataSource, NSTableViewDelegate, HandyTableViewDelegate {
  public var abbrevEntry: AbbrevEntry? {
    get {
      return _abbrevEntry
    }
    set(e) {
      _abbrevEntry = e
      variants = e?.variants ?? []
    }
  }
  private var _abbrevEntry: AbbrevEntry? = nil
  private var variants: [AbbrevBase] = []
  
  // NSTableViewDataSource
  
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
        case "result": return abbrevEntry?.variantExpansion(v)
        default: return nil
        }
      }
    }
    return nil
  }
  
  // NSTableViewDelegate
  
  public func tableView(_ tableView: NSTableView, shouldEdit tableColumn: NSTableColumn?, row: Int) -> Bool {
    return !(tableColumn?.identifier == "result")
  }
  
  // HandyTableViewDelegate
  
  public func tableViewCanDeleteEmptyRow(_ view: HandyTableView, row: NSInteger) -> Bool {
    return false
  }
  
  public func tableViewClickedBelowLastRow(_ view: HandyTableView, point: NSPoint) -> Bool {
    return false
  }
}

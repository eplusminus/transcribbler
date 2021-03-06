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

import Cocoa
import Foundation
import HelperViews

@objc(AbbrevListController)
public class AbbrevListController: NSViewController {
  static let ClosedNotification = NSNotification.Name("AbbrevListClosed")
  
  @IBOutlet private(set) var tableContainerView: NSView!
  @IBOutlet private(set) var tableView: HandyTableView!
  @IBOutlet private(set) var tableViewDelegate: AbbrevTableViewDelegate!
  @IBOutlet private(set) var labelField: NSTextField!
  @IBOutlet private(set) var collapseButton: NSButton!
  @IBOutlet private(set) var suffixEditor: AbbrevSuffixEditor!
  
  public private(set) var document: AbbrevListDocument
  public var displayName: String {
    get {
      return document.displayName
    }
  }
  
  public var collapsed: Bool = false
  private var exactHeightConstraint: NSLayoutConstraint? = nil
  private var minHeightConstraint: NSLayoutConstraint? = nil
  private var savedHeight: CGFloat = 0
  
  public init(_ document: AbbrevListDocument) {
    self.document = document
    super.init(nibName: "AbbrevListView", bundle: Bundle.main)!
  }
  
  required public init?(coder aDecoder: NSCoder) {
    return nil
  }
  
  override public func awakeFromNib() {
    tableViewDelegate.table = document.controller
    tableViewDelegate.resolver = document.abbrevResolver
    tableView?.reloadData()
    
    suffixEditor.addObserver(self, forKeyPath: "variants", options: .new, context: nil)

    let headerBarHeight = self.view.frame.height -
      (tableContainerView.frame.origin.y + tableContainerView.frame.size.height)
    exactHeightConstraint = NSLayoutConstraint(item: view, attribute: .height, relatedBy: .equal,
                                               toItem: nil, attribute: .height, multiplier: 0,
                                               constant: headerBarHeight)
    minHeightConstraint = NSLayoutConstraint(item: view, attribute: .height, relatedBy: .greaterThanOrEqual,
                                               toItem: nil, attribute: .height, multiplier: 0,
                                               constant: headerBarHeight)
  }
  
  @IBAction public func collapseAbbreviationList(_ sender: AnyObject?) {
    collapsed = !collapsed
    tableContainerView.isHidden = collapsed
    if collapsed {
      savedHeight = view.frame.height
      view.addConstraint(exactHeightConstraint!)
      view.needsLayout = true
    }
    else {
      view.removeConstraint(exactHeightConstraint!)
      view.layout()
      minHeightConstraint?.constant = savedHeight
      view.addConstraint(minHeightConstraint!)
      view.layout()
      view.removeConstraint(minHeightConstraint!)
    }
    collapseButton.state = collapsed ? NSOnState : NSOffState
  }
  
  @IBAction public func closeAbbreviationList(_ sender: AnyObject?) {
    if !document.isDefaultList {
      document.abbrevResolver?.removeProvider(document)
      NotificationCenter.default.post(name: AbbrevListController.ClosedNotification, object: self)
    }
  }
  
  @IBAction public func saveAbbreviationListAs(_ sender: AnyObject?) {
    document.runModalSavePanel(for: .saveAsOperation, delegate: nil, didSave: nil, contextInfo: nil)
  }
  
  @IBAction public func toggleSuffixes(_ sender: Any) {
    if suffixEditor.isPopoverOpen {
      suffixEditor.popover.close()
      tableView.window?.makeFirstResponder(tableView)
    }
    else {
      let sri = tableView.selectedRowIndexes
      if sri.count == 1 {
        let sr = tableView.selectedRow
        if let ae = tableViewDelegate.entryAtIndex(sr) {
          suffixEditor.abbrevEntry = ae
          let selectionFrame = tableView.frameOfCell(atColumn: 1, row: tableView.selectedRow)
          suffixEditor.popover.show(relativeTo: selectionFrame, of: tableView, preferredEdge: NSRectEdge.maxY)
          suffixEditor.popover.nextResponder = tableView
        }
      }
    }
  }
  
  override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    if keyPath == "variants" {
      if tableView.selectedRowIndexes.count == 1 {
        let sr = tableView.selectedRow
        if let a0 = tableViewDelegate.entryAtIndex(sr) {
          let vs = suffixEditor.variants
          let a1 = AbbrevEntry(abbreviation: a0.abbreviation, expansion: a0.expansion,
                               variants: (vs.count > 0) ? vs : nil)
          tableViewDelegate.replaceEntryAtIndex(sr, a1)
        }
      }
    }
  }
  
  //
  // NSMenuValidation
  //
  
  override public func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
    if let a = menuItem.action {
      switch a {
      case #selector(closeAbbreviationList),
           #selector(collapseAbbreviationList),
           #selector(saveAbbreviationListAs):
        return !document.isDefaultList
      case #selector(toggleSuffixes(_:)):
        menuItem.state = suffixEditor.isPopoverOpen ? NSOnState : NSOffState
        return tableView.selectedRowIndexes.count == 1;
      default:
        return false
      }
    }
    return false
  }
}

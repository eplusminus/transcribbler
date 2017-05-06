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

import Cocoa
import Foundation
import HelperViews

@objc(AbbrevListController)
public class AbbrevListController: NSViewController {
  static let ClosedNotification = NSNotification.Name("AbbrevListClosed")
  
  @IBOutlet private(set) var tableView: HandyTableView!
  @IBOutlet private(set) var tableViewDelegate: AbbrevTableViewDelegate!
  @IBOutlet private(set) var disclosureView: DisclosureView!
  
  public private(set) var document: AbbrevListDocument
  public var displayName: String {
    get {
      return document.displayName
    }
  }
  
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

    disclosureView.bind("title", to: document, withKeyPath: "displayName", options: nil)
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
  
  //
  // NSMenuValidation
  //
  
  override public func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
    if let a = menuItem.action {
      switch a {
      case #selector(closeAbbreviationList),
           #selector(saveAbbreviationListAs):
        return !document.isDefaultList
      default:
        return false
      }
    }
    return false
  }
}

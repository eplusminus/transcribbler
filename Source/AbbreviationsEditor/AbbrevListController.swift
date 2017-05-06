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
  
  @IBOutlet private(set) var tableView: HandyTableView? = nil
  @IBOutlet private(set) var tableViewDelegate: AbbrevTableViewDelegate? = nil
  @IBOutlet private(set) var disclosureView: DisclosureView!
  @IBOutlet private(set) var actionButton: NSButton!
  
  private var _document: AbbrevListDocument? = nil
  public var document: AbbrevListDocument? {
    get {
      return _document
    }
    set(newDoc) {
      self._document = newDoc
      if let d = newDoc {
        disclosureView.title = NSLocalizedString(d.isDefaultList ? "MainAbbrevList" : "NewAbbrevList", comment: "")
        tableViewDelegate?.table = d.controller
        tableViewDelegate?.resolver = d.abbrevResolver
        tableView?.reloadData()
      }
    }
  }
  
  public init() {
    super.init(nibName: "AbbrevListView", bundle: Bundle.main)!
  }
  
  required public init?(coder aDecoder: NSCoder) {
    super.init(nibName: "AbbrevListView", bundle: Bundle.main)!
  }
  
  override public func awakeFromNib() {
    actionButton.removeFromSuperview()
    disclosureView.addSubview(actionButton)
    actionButton.frame.origin = NSMakePoint(disclosureView.frame.size.width - actionButton.frame.size.width,
      disclosureView.frame.size.height - actionButton.frame.size.height)
  }
  
  @IBAction public func closeAbbreviationList(_ sender: Any) {
    if let d = document {
      if !d.isDefaultList {
        d.abbrevResolver?.removeProvider(d)
        NotificationCenter.default.post(name: AbbrevListController.ClosedNotification, object: self)
      }
    }
  }
  
  @IBAction public func saveAbbreviationListAs(_ sender: Any) {
    
  }
  
  //
  // NSMenuValidation
  //
  
  override public func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
    if let a = menuItem.action {
      switch a {
      case #selector(closeAbbreviationList),
           #selector(saveAbbreviationListAs):
        return !(document?.isDefaultList ?? true)
      default:
        return false
      }
    }
    return false
  }
}

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

@objc(AbbrevsController)
public class AbbrevsController: NSWindowController {
  @IBOutlet private(set) var splitView: NSSplitView!
  
  public var isPanelVisible: Bool {
    get {
      return window?.isVisible ?? false
    }
    set(v) {
      window?.setIsVisible(v)
    }
  }
  
  public private(set) static var sharedInstance: AbbrevsController? = nil

  private var listControllers: [AbbrevListController] = []
  private var wasVisibleBeforeFullScreen: Bool = false
  
  override public var windowNibName: String? {
    get {
      return "AbbrevsPanel"
    }
  }
  
  override public func awakeFromNib() {
    let _ = window  // triggers lazy loading
    let _ = addAbbrevListDocument(AbbrevListDocument.default)
    if AbbrevsController.sharedInstance == nil {
      AbbrevsController.sharedInstance = self
    }
  }
  
  public func addAbbrevListDocument(_ document: AbbrevListDocument) -> AbbrevListController {
    if let alc = listControllers.first(where: { alc in alc.document === document }) {
      return alc
    }
    if (!document.isDefaultList) {
      AbbrevListDocument.default.abbrevResolver?.addProvider(document)
    }
    let alc = AbbrevListController(document)
    let alcv = alc.view
    splitView.addSubview(alcv)
    splitView.adjustSubviews()
    NotificationCenter.default.addObserver(self, selector: #selector(abbrevListClosed(_:)), name: AbbrevListController.ClosedNotification, object: alc)
    listControllers.append(alc)
    return alc
  }
  
  @objc private func abbrevListClosed(_ notification: NSNotification) {
    if let alc = notification.object as? AbbrevListController {
      if let i = listControllers.index(of: alc) {
        listControllers.remove(at: i)
        alc.view.removeFromSuperview()
      }
    }
  }
  
  @IBAction public func toggleAbbrevsPanel(_ sender: AnyObject?) {
    isPanelVisible = !isPanelVisible
  }
  
  @IBAction public func newAbbreviation(_ sender: AnyObject?) {
    isPanelVisible = true
    if let alc = listControllers.first {
      window?.makeKey()
      window?.makeFirstResponder(alc.tableView)
      alc.tableViewDelegate.add(sender)
    }
  }

  @IBAction public func newAbbreviationList(_ sender: AnyObject?) {
    let alc = addAbbrevListDocument(AbbrevListDocument())
    isPanelVisible = true
    NSApp.mainWindow?.makeFirstResponder(alc.tableView)
    alc.tableViewDelegate.add(sender)
  }
  
  public func lendViewsTo(stackingView: StackingView) {
    wasVisibleBeforeFullScreen = isPanelVisible
    isPanelVisible = false
    splitView.removeFromSuperview()
    stackingView.addSubview(splitView)
  }
  
  public func restoreViews() {
    splitView.removeFromSuperview()
    if let cv = window?.contentView {
      cv.addSubview(splitView)
      splitView.frame = cv.frame
      splitView.adjustSubviews()
    }
    isPanelVisible = wasVisibleBeforeFullScreen
  }
  
  //
  // NSMenuValidation
  //
  
  override public func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
    if let a = menuItem.action {
      switch a {
      case #selector(newAbbreviation),
           #selector(newAbbreviationList):
        return true
      case #selector(toggleAbbrevsPanel(_:)):
        menuItem.state = isPanelVisible ? NSOnState : NSOffState
        return true
      default:
        return false
      }
    }
    return false;
  }
}

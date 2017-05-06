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
public class AbbrevsController: NSViewController {
  @IBOutlet private(set) var drawer: NSDrawer?
  @IBOutlet private(set) var stackingView: NSStackView? = nil
  @IBOutlet var textView: NSView? {
    get {
      return _textView
    }
    set(tv) {
      if (_textView != tv) {
        _textView = tv
        // tableView?.backTabDestination = tv;
        // TODO
      }
    }
  }
  
  private var listControllers: [AbbrevListController] = []
  private var _textView: NSView? = nil
  
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    var objects = NSArray()
    Bundle.main.loadNibNamed("AbbrevDrawerView", owner: self, topLevelObjects: &objects)
  }
  
  override public func awakeFromNib() {
    if let d = drawer {
      if (d.contentView != view) {
        let size = view.frame.size
        view.autoresizesSubviews = true
        d.contentSize = size
        d.minContentSize = size
        d.contentView = view
      }
    }
  }
  
  public func addAbbrevListDocument(_ document: AbbrevListDocument) {
    let alc = AbbrevListController()
    let alcv = alc.view
    alc.document = document
    stackingView?.addView(alcv, in: .bottom)
    NotificationCenter.default.addObserver(self, selector: #selector(abbrevListClosed(_:)), name: AbbrevListController.ClosedNotification, object: alc)
    listControllers.append(alc)
  }
  
  @objc private func abbrevListClosed(_ notification: NSNotification) {
    if let alc = notification.object as? AbbrevListController {
      if let i = listControllers.index(of: alc) {
        listControllers.remove(at: i)
        alc.view.removeFromSuperview()
      }
    }
  }
  
  @IBAction public func newAbbreviation(_ sender: Any?) {
    drawer?.open()
    // NSApp.sendAction(#selector(AbbrevTableViewDelegate.add), to: tableViewDelegate, from: self)
    // TODO
  }
  
  @IBAction public func newAbbreviationList(_ sender: Any?) {
    addAbbrevListDocument(AbbrevListDocument())
  }
  
  @IBAction public func openAbbreviationList(_ sender: Any?) {
    
  }
  
  public func lendViewsTo(stackingView: StackingView) {
    for lc in listControllers {
      let v = lc.view
      v.removeFromSuperview()
      stackingView.addSubview(v)
    }
  }
  
  public func restoreViews() {
    for lc in listControllers {
      let v = lc.view
      v.removeFromSuperview()
      self.stackingView?.addSubview(v)
    }
  }
  
  //
  // NSMenuValidation
  //
  
  override public func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
    if let a = menuItem.action {
      switch a {
      case #selector(newAbbreviation),
           #selector(newAbbreviationList),
           #selector(openAbbreviationList):
        return true
      default:
        return false
      }
    }
    return false
  }
}

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
  @IBOutlet private(set) var containerView: NSView!
  @IBOutlet private(set) var listView: NSView? = nil
  @IBOutlet private(set) var tableView: HandyTableView? = nil
  @IBOutlet private(set) var tableViewDelegate: AbbrevTableViewDelegate? = nil
  @IBOutlet var textView: NSView? {
    get {
      return _textView
    }
    set(tv) {
      if (_textView != tv) {
        _textView = tv
        tableView?.backTabDestination = tv;
      }
    }
  }
  @IBOutlet private(set) var disclosureView: DisclosureView!
  
  var document: AbbrevListDocument? = nil
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
    disclosureView.fixedHeight = false
  }
  
  public func addAbbrevListDocument(_ document: AbbrevListDocument) {
    if (self.document == nil) {
      self.document = document
      if (listView == nil) {
        Bundle.main.loadNibNamed("AbbrevListView", owner: self, topLevelObjects: nil)
      }
      if let lv = listView {
        lv.setFrameOrigin(NSMakePoint(0, 0))
        lv.setFrameSize(containerView.frame.size)
        lv.autoresizingMask = [NSAutoresizingMaskOptions.viewWidthSizable,
                               NSAutoresizingMaskOptions.viewHeightSizable];
        containerView.addSubview(lv)
      }
      tableView?.backTabDestination = textView
      tableViewDelegate?.table = document.controller
      tableViewDelegate?.resolver = document.abbrevResolver
      tableView?.reloadData()
    }
  }
  
  @IBAction public func newAbbreviation(_ sender: Any) {
    drawer?.open()
    NSApp.sendAction(#selector(AbbrevTableViewDelegate.add), to: tableViewDelegate, from: self)
  }
  
  public func lendViewsTo(stackingView: StackingView) {
    if let lv = listView {
      lv.removeFromSuperview();
      if let cv = disclosureView.contentView {
        cv.addSubview(lv)
        lv.frame = cv.frame
      }
    }
    stackingView.addSubview(disclosureView)
  }
  
  public func restoreViews() {
    disclosureView.removeFromSuperview()
    if let lv = listView {
      lv.removeFromSuperview()
      containerView.addSubview(lv)
      lv.frame = NSMakeRect(0, 0, containerView.frame.size.width, containerView.frame.size.height)
    }
  }
  
  //
  // protocol NSMenuValidation
  //
  
  override public func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
    if menuItem.action == #selector(newAbbreviation) {
      return true;
    }
    return false;
  }
}

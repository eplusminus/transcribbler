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

import AbbreviationsEditor
import HelperViews
import Media

import Foundation


let defaultSidebarWidthValue: CGFloat = 200
let minimumSidebarWidthValue: CGFloat = 126
let sidebarInset: CGFloat = 4
let sidebarWidthKey = "SidebarWidth"
let sidebarHiddenKey = "SidebarHidden"

let bothShiftKeys = NSEventModifierFlags.shift.union(NSEventModifierFlags(rawValue: 0x06))


fileprivate struct FullScreenSavePanelState {
  var panel: CanBorrowViewForFullScreen
  var wasVisible: Bool
}

@objc(TransTextWindowController)
public class TransTextWindowController: NSWindowController,
    NSWindowDelegate, NSSplitViewDelegate, NSUserInterfaceValidations {
  @IBOutlet private(set) var mediaController: MediaController!
  
  @IBOutlet private(set) var mainContentView: NSView!
  @IBOutlet private(set) var textView: TransTextView!
  @IBOutlet private(set) var scrollView: NSScrollView!
  @IBOutlet private(set) var fullScreenSplitView: NSSplitView!
  @IBOutlet private(set) var fullScreenSidebarView: NSView!
  @IBOutlet private(set) var fullScreenSidebarStackView: NSStackView!
  
  var fullScreen: Bool = false
  var toolbar: NSToolbar?
  var toolbarVisibleDefault: Bool = false
  var toolbarVisibleInFullScreen: Bool = false
  fileprivate var panelsBeforeFullScreen: [FullScreenSavePanelState] = []
  
  override public func windowDidLoad() {
    super.windowDidLoad()
    
    self.window?.collectionBehavior = NSWindowCollectionBehavior.fullScreenPrimary
  
    // Insert the media controller into the responder chain after the text view, so that we can
    // trigger commands like "play/pause" while editing text.
    mediaController.nextResponder = textView.nextResponder
    textView.nextResponder = mediaController
    
    toolbarVisibleInFullScreen = false
    
    fullScreenSplitView.delegate = self
    
    if defaultSidebarWidth <= 0 {
      defaultSidebarWidth = fullScreenSidebarView.frame.width
    }
    
    document?.windowControllerDidLoadNib(self)
  }
  
  override public func flagsChanged(with event: NSEvent) {
    if event.modifierFlags.contains(bothShiftKeys) {
      NSApp.sendAction(#selector(MediaController.replay(_:)), to: nil, from: self)
    }
  }

  @IBAction public func toggleMediaPanel(_ sender: Any) {
    mediaController.isPanelVisible = !mediaController.isPanelVisible
  }

  @IBAction public func toggleRuler(_ sender: Any) {
    textView.isRulerVisible = !textView.isRulerVisible
  }
  
  //
  // NSWindowDelegate
  //
  
  public func windowWillReturnFieldEditor(_ sender: NSWindow, to client: Any?) -> Any? {
    return HandyTableView.windowWillReturnFieldEditor(sender, toObject: client)
  }

  public func windowWillEnterFullScreen(_ notification: Notification) {
    let w = window!
    
    toolbar = window?.toolbar
    toolbarVisibleDefault = toolbar?.isVisible ?? false
    w.toolbar = nil
    
    let scaledWidth = defaultSidebarWidth * w.frame.size.width
      / (NSScreen.main()?.frame.size.width ?? 1)
    
    panelsBeforeFullScreen = []
    var borrowedViews: [NSView] = []
    for cbv in [mediaController as CanBorrowViewForFullScreen,
                AbbrevsController.sharedInstance! as CanBorrowViewForFullScreen] {
      let w = cbv.getFullScreenHideableWindow()
      let fss = FullScreenSavePanelState(panel: cbv,
                                         wasVisible: w?.isVisible ?? false)
      panelsBeforeFullScreen.append(fss)
      w?.setIsVisible(false)
      if let v = cbv.borrowViewForFullScreen() {
        borrowedViews.append(v)
        v.removeFromSuperview()
      }
    }
    fullScreenSidebarStackView.setViews(borrowedViews, in: .top)
    
    fullScreenSplitView.frame = w.contentView!.frame
    mainContentView.removeFromSuperview()
    fullScreenSplitView.addSubview(mainContentView)
    fullScreenSplitView.setPosition(scaledWidth, ofDividerAt: 0)
    fullScreenSidebarView?.isHidden = defaultSidebarHidden
    
    w.contentView?.addSubview(fullScreenSplitView)

    textView.textContainerInset = NSMakeSize(100, 30)
  }

  public func windowDidEnterFullScreen(_ notification: Notification) {
    // set splitter position again in case scaledWidth had a rounding error
    if !fullScreenSidebarView.isHidden {
      fullScreenSplitView.setPosition(defaultSidebarWidth, ofDividerAt: 0)
    }
  }
  
  public func windowWillExitFullScreen(_ notification: Notification) {
    defaultSidebarWidth = fullScreenSidebarView?.frame.size.width ?? 0
    defaultSidebarHidden = fullScreenSidebarView?.isHidden ?? false
    
    let cf = window!.contentView!.frame
    mainContentView.removeFromSuperview()
    fullScreenSplitView.removeFromSuperview()
    mainContentView.frame = cf
    window!.contentView?.addSubview(mainContentView)
    
    fullScreenSidebarStackView.setViews([], in: .top)
    for fss in panelsBeforeFullScreen {
      fss.panel.restoreViewFromFullScreen()
      fss.panel.getFullScreenHideableWindow()?.setIsVisible(fss.wasVisible)
    }
    panelsBeforeFullScreen = []
    
    textView.textContainerInset = NSMakeSize(0, 0)
  }

  public func windowDidExitFullScreen(_ notification: Notification) {
    window!.toolbar = toolbar
    toolbar?.isVisible = toolbarVisibleDefault
    toolbar = nil
  }
  
  //
  // NSSplitViewDelegate
  //
  
  public func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
    return subview == fullScreenSidebarView
  }

  public func splitView(_ splitView: NSSplitView, constrainMinCoordinate proposedMin: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
    return (dividerIndex == 0) ? minimumSidebarWidthValue : proposedMin
  }
  
  public func splitView(_ splitView: NSSplitView, shouldCollapseSubview subview: NSView, forDoubleClickOnDividerAt dividerIndex: Int) -> Bool {
    return true
  }

  //
  // protocol NSUserInterfaceValidations
  //
  
  public func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
    let a = item.action
    if a == #selector(toggleMediaPanel(_:)) {
      if let m = item as? NSMenuItem {
        m.state = mediaController.isPanelVisible ? NSOnState : NSOffState
      }
      return true
    }
    if a == #selector(toggleRuler(_:)) {
      return true
    }
    return false
  }

  //
  // internal
  //
  
  private var defaultSidebarWidth: CGFloat {
    get {
      return CGFloat(UserDefaults.standard.float(forKey: sidebarWidthKey))
    }
    set(f) {
      UserDefaults.standard.set((f <= 0) ? -1 : f, forKey: sidebarWidthKey)
    }
  }
  
  private var defaultSidebarHidden: Bool {
    get {
      return UserDefaults.standard.bool(forKey: sidebarHiddenKey)
    }
    set(f) {
      UserDefaults.standard.set(f, forKey: sidebarHiddenKey)
    }
  }
}

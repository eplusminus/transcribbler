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

import Foundation


let defaultSidebarWidthValue: CGFloat = 200
let minimumSidebarWidthValue: CGFloat = 126
let sidebarInset: CGFloat = 4
let sidebarWidthKey = "SidebarWidth"
let sidebarHiddenKey = "SidebarHidden"

let bothShiftKeys = NSEventModifierFlags.shift.union(NSEventModifierFlags(rawValue: 0x06))


@objc(TransTextWindowController)
public class TransTextWindowController: NSWindowController,
    NSWindowDelegate, NSDrawerDelegate, NSSplitViewDelegate, NSUserInterfaceValidations {
  @IBOutlet private(set) var mediaController: MediaController!
  @IBOutlet private(set) var abbrevsController: AbbrevsController!
  
  @IBOutlet private(set) var mainContentView: NSView!
  @IBOutlet private(set) var textView: TransTextView!
  @IBOutlet private(set) var scrollView: NSScrollView!
  @IBOutlet private(set) var mediaDrawer: NSDrawer!
  @IBOutlet private(set) var abbrevDrawer: NSDrawer!
  
  var fullScreen: Bool = false
  var toolbar: NSToolbar?
  var splitter: NSSplitView?
  var fullScreenSidebarView: NSView?
  var stackingView: StackingView?
  var toolbarVisibleDefault: Bool = false
  var toolbarVisibleInFullScreen: Bool = false
  
  override public func windowDidLoad() {
    super.windowDidLoad()
    
    self.window?.collectionBehavior = NSWindowCollectionBehavior.fullScreenPrimary
  
    // Insert the two drawer controllers into the responder chain after the text view, so that we can
    // trigger commands like "play/pause" and "new abbreviation" while editing text.
    mediaController.nextResponder = textView.nextResponder
    abbrevsController.nextResponder = mediaController
    textView.nextResponder = abbrevsController
    
    mediaDrawer.delegate = self
    abbrevDrawer.delegate = self
    
    toolbarVisibleInFullScreen = false
    
    let r0 = NSMakeRect(0, 0, defaultSidebarWidthValue, defaultSidebarWidthValue)
    let sp = NSSplitView(frame: r0)
    sp.isVertical = true
    sp.dividerStyle = NSSplitViewDividerStyle.thin
    sp.autoresizingMask = [NSAutoresizingMaskOptions.viewWidthSizable, NSAutoresizingMaskOptions.viewHeightSizable]
    sp.delegate = self
    splitter = sp

    let r1 = NSMakeRect(0, 0, minimumSidebarWidthValue, defaultSidebarWidthValue)
    let fssv = NSView(frame: r1)
    let sv = StackingView(frame: NSInsetRect(r1, sidebarInset, sidebarInset))
    sv.autoresizingMask = [NSAutoresizingMaskOptions.viewWidthSizable, NSAutoresizingMaskOptions.viewHeightSizable]
    fssv.addSubview(sv)
    sp.addSubview(fssv)
    fullScreenSidebarView = fssv
    stackingView = sv
    
    document?.windowControllerDidLoadNib(self)
  }
  
  override public func flagsChanged(with event: NSEvent) {
    if event.modifierFlags.contains(bothShiftKeys) {
      NSApp.sendAction(#selector(MediaController.replay(_:)), to: nil, from: self)
    }
  }

  @IBAction public func toggleMediaDrawer(_ sender: Any) {
    isMediaDrawerOpen = !isMediaDrawerOpen
  }

  @IBAction public func toggleAbbrevDrawer(_ sender: Any) {
    isAbbrevDrawerOpen = !isAbbrevDrawerOpen
  }

  @IBAction public func toggleRuler(_ sender: Any) {
    textView.isRulerVisible = !textView.isRulerVisible
  }

  public var isMediaDrawerOpen: Bool {
    get {
      return mediaDrawer.state == Int(NSDrawerState.openState.rawValue)
    }
    set(s) {
      setDrawerState(mediaDrawer, open: s)
    }
  }
  
  public var isAbbrevDrawerOpen: Bool {
    get {
      return abbrevDrawer.state == Int(NSDrawerState.openState.rawValue)
    }
    set(s) {
      setDrawerState(abbrevDrawer, open: s)
    }
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
    
    splitter?.frame = w.contentView!.frame
    mainContentView.removeFromSuperview()
    splitter?.addSubview(mainContentView)
    splitter?.setPosition(scaledWidth, ofDividerAt: 0)
    fullScreenSidebarView?.isHidden = defaultSidebarHidden
    
    w.contentView?.addSubview(splitter!)
    
    mediaController.lendViewsToStackingView(stackingView!)
    abbrevsController.lendViewsTo(stackingView: stackingView!)
    
    textView.textContainerInset = NSMakeSize(100, 30)
  }

  public func windowDidEnterFullScreen(_ notification: Notification) {
    // set splitter position again in case scaledWidth had a rounding error
    if !(fullScreenSidebarView?.isHidden ?? false) {
      splitter?.setPosition(defaultSidebarWidth, ofDividerAt: 0)
    }
  }
  
  public func windowWillExitFullScreen(_ notification: Notification) {
    defaultSidebarWidth = fullScreenSidebarView?.frame.size.width ?? 0
    defaultSidebarHidden = fullScreenSidebarView?.isHidden ?? false
    
    let cf = window!.contentView!.frame
    mainContentView.removeFromSuperview()
    splitter?.removeFromSuperview()
    mainContentView.frame = cf
    window!.contentView?.addSubview(mainContentView)
    
    mediaController.restoreViews()
    abbrevsController.restoreViews()
    
    textView.textContainerInset = NSMakeSize(0, 0)
  }

  public func windowDidExitFullScreen(_ notification: Notification) {
    window!.toolbar = toolbar
    toolbar?.isVisible = toolbarVisibleDefault
    toolbar = nil
  }
  
  //
  // NSDrawerDelegate
  //
  
  public func drawerDidOpen(_ notification: Notification) {
    if let drawer = notification.object as? NSDrawer {
      let sf = window!.screen!.visibleFrame
      let df = drawer.contentView!.window!.frame
      if !NSContainsRect(sf, df) {
        window!.zoom(nil)
      }
    }
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
    if a == #selector(toggleMediaDrawer(_:)) {
      if let m = item as? NSMenuItem {
        m.state = mediaDrawer.state
      }
      return true
    }
    if a == #selector(toggleAbbrevDrawer(_:)) {
      if let m = item as? NSMenuItem {
        m.state = abbrevDrawer.state
      }
      return true
    }
    if a == #selector(toggleRuler(_:)) {
      return true
    }
    if a == #selector(AbbrevsController.newAbbreviation) {
      return true
    }
    return false
  }

  //
  // internal
  //
  
  private var defaultSidebarWidth: CGFloat {
    get {
      let f = CGFloat(UserDefaults.standard.float(forKey: sidebarWidthKey))
      return (f == 0) ? defaultSidebarWidthValue : ((f < 0) ? 0 : f)
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
  
  private func setDrawerState(_ drawer: NSDrawer, open: Bool) {
    if (open) {
      drawer.open(on: (drawer == mediaDrawer) ? NSRectEdge.minX : NSRectEdge.maxX)
    }
    else {
      drawer.close()
    }
  }
}

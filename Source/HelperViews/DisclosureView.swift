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

import Foundation

let kDefaultTitleHeight = CGFloat(26)
let kDefaultButtonLeft = CGFloat(2)
let kDefaultLabelLeft = CGFloat(20)
let kButtonBottomMargin = CGFloat(5)
let kLabelBottomMargin = CGFloat(2)
let kButtonSize = CGFloat(13)
let kLabelHeight = CGFloat(18)

@objc(DisclosureView)
public class DisclosureView: NSView, ViewSizeLimits {
  @IBOutlet private(set) var disclosureButton: NSButton!
  @IBOutlet private(set) var label: NSTextField!

  public var contentView: NSView?
  private var _title: String?
  @IBInspectable public var title: String? {
    get {
      return _title
    }
    set(t) {
      _title = t
      label?.stringValue = t ?? ""
    }
  }
  private var inited: Bool = false
  private var _enabled: Bool = true
  @IBInspectable public var enabled: Bool {
    get {
      return _enabled
    }
    set(e) {
      if (_enabled != e) {
        _enabled = e
        disclosureButton.isHidden = !e
      }
    }
  }
  private var _expanded: Bool = true
  @IBInspectable public var expanded: Bool {
    get {
      return _expanded
    }
    set(e) {
      if (_expanded != e) {
        _expanded = e
        disclosureButton.state = e ? NSOnState : NSOffState
        if let cv = contentView {
          let f = self.frame
          if (!e) {
            preferredHeight = cv.frame.size.height
          }
          let newHeight = e ? (preferredHeight + titleHeight) : titleHeight
          let r = NSMakeRect(f.origin.x, f.origin.y - (newHeight - f.size.height),
                             f.size.width, newHeight)
          if (e) {
            self.frame = r
            resizeContentView()
            addSubview(cv)
          }
          else {
            cv.removeFromSuperview()
            self.frame = r
          }
          self.needsDisplay = true
        }
      }
    }
  }
  @IBInspectable public var fixedHeight: Bool = true
  private var _indentContent: Bool = false
  @IBInspectable public var indentContent: Bool {
    get {
      return _indentContent
    }
    set(i) {
      if (_indentContent != i) {
        _indentContent = i
        resizeContentView()
      }
    }
  }
  public var titleHeight: CGFloat = kDefaultTitleHeight
  private var _preferredHeight: CGFloat = 0
  public var preferredHeight: CGFloat {
    get {
      return _preferredHeight
    }
    set(h) {
      if (_preferredHeight != h) {
        _preferredHeight = h
        if (expanded) {
          self.setFrameSize(NSMakeSize(frame.size.width, titleHeight + h))
          resizeContentView()
        }
      }
    }
  }
  public var preferredWidth: CGFloat = 0
  
  override init(frame f: NSRect) {
    super.init(frame: f)
    super.autoresizesSubviews = false
    preferredWidth = f.size.width
    _preferredHeight = f.size.height
  }
  
  required public init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override public func awakeFromNib() {
    if inited {
      return
    }
    inited = true
    
    if title == nil {
      title = toolTip
    }
    
    let cv = NSView(frame: self.frame)
    contentView = cv
    for v in subviews {
      v.removeFromSuperview()
      cv.addSubview(v)
    }
    cv.autoresizesSubviews = true
    cv.autoresizingMask = [NSAutoresizingMaskOptions.viewWidthSizable,
      NSAutoresizingMaskOptions.viewHeightSizable]
    if !fixedHeight {
      _preferredHeight -= titleHeight
    }
    cv.frame = makeContentViewFrame()
    
    super.autoresizesSubviews = true
    setFrameSize(NSMakeSize(preferredWidth, preferredHeight + titleHeight))
    
    if expanded {
      addSubview(cv)
    }
    
    let buttonFrame = NSMakeRect(kDefaultButtonLeft, preferredHeight + kButtonBottomMargin,
                                 kButtonSize, kButtonSize);
    disclosureButton = NSButton(frame: buttonFrame)
    disclosureButton.autoresizingMask = [NSAutoresizingMaskOptions.viewMaxXMargin,
                                         NSAutoresizingMaskOptions.viewMinYMargin]
    disclosureButton.setButtonType(NSOnOffButton)
    disclosureButton.bezelStyle = NSDisclosureBezelStyle
    disclosureButton.title = ""
    disclosureButton.target = self
    disclosureButton.action = #selector(toggle)
    disclosureButton.state = expanded ? NSOnState : NSOffState
    disclosureButton.isHidden = !enabled
    addSubview(disclosureButton)
    
    let labelFrame = NSMakeRect(kDefaultLabelLeft, preferredHeight + kLabelBottomMargin,
                                preferredWidth - (kDefaultLabelLeft + 2), kLabelHeight)
    label = NSTextField(frame: labelFrame)
    label.autoresizingMask = [NSAutoresizingMaskOptions.viewWidthSizable,
                              NSAutoresizingMaskOptions.viewMinYMargin]
    label.isEditable = false
    label.stringValue = title ?? ""
    label.isBordered = false
    label.drawsBackground = false
    addSubview(label)
  }

  override public func resizeSubviews(withOldSize oldSize: NSSize) {
    super.resizeSubviews(withOldSize: oldSize)
    if expanded {
      let f = frame
      preferredHeight = f.size.height - titleHeight
      resizeContentView()
    }
  }
  
  public func toggle(_ sender: Any) {
    if ((sender as! NSObject) != disclosureButton) {
      disclosureButton.state = (disclosureButton.state == NSOnState) ? NSOffState : NSOnState
    }
    expanded = (disclosureButton.state == NSOnState)
  }

  public func minimumSize() -> NSSize {
    return NSMakeSize(preferredWidth, expanded ? (preferredHeight + titleHeight) : titleHeight)
  }
  
  public func maximumSize() -> NSSize {
    return expanded ?
      NSMakeSize(preferredWidth, fixedHeight ? (preferredHeight + titleHeight) : CGFloat(FLT_MAX)) :
      minimumSize()
  }

  func makeContentViewFrame() -> NSRect {
    let x = indentContent ? kDefaultLabelLeft : 0
    return NSMakeRect(x, 0, frame.size.width - x, preferredHeight)
  }
  
  func resizeContentView() {
    if let cv = contentView {
      cv.frame = makeContentViewFrame()
    }
  }
}


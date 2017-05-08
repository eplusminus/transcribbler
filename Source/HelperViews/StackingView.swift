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

@objc(StackingView)
public class StackingView: NSView {
  @IBInspectable public var margin: CGFloat {
    get {
      return _margin
    }
    set(m) {
      if m != _margin {
        _margin = m
        if inited {
          updateLayout()
        }
      }
    }
  }
  private var _margin: CGFloat = 0
  private var inited: Bool = false
  private var updating: Bool = false
  private var dirty: Bool = false
  
  override public func awakeFromNib() {
    inited = true
    updateLayout()
  }

  override public func didAddSubview(_ view: NSView) {
    view.addObserver(self, forKeyPath: "hidden", options: [], context: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(subviewFrameChanged),
                                           name: NSNotification.Name.NSViewFrameDidChange, object: view)
    if inited {
      updateLayout()
    }
  }

  override public func willRemoveSubview(_ view: NSView) {
    if view.superview == self && !isCustomView(view) {
      view.removeObserver(self, forKeyPath: "hidden")
      NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NSViewFrameDidChange, object: view)
    }
  }
  
  func isCustomView(_ view: NSView) -> Bool {
    return false; // TODO
  }
  
  override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    if (keyPath == "hidden") {
      updateLayout()
    }
  }

  override public func resizeSubviews(withOldSize oldSize: NSSize) {
    updateLayout()
  }
  
  func subviewFrameChanged(_ sender: Any) {
    if updating {
      dirty = true
    }
    else {
      updateLayout()
    }
  }

  func updateLayout() {
    if updating {
      return
    }
    updating = true
    
    repeat {
      dirty = false
      var changed = false
      
      let fixedWidth = frame.size.width
      var minSpaceUsed: CGFloat = 0
      var varHeightCount = 0
      
      for v in subviews {
        if !v.isHidden {
          let min = minimumHeight(v)
          let max = maximumHeight(v)
          minSpaceUsed += min + _margin
          if (max > min) {
            varHeightCount += 1
          }
        }
      }
      if minSpaceUsed > 0 {
        minSpaceUsed -= _margin
      }
      let availableHeight: CGFloat = frame.size.height - minSpaceUsed
      var pos: CGFloat = frame.size.height
      for v in subviews {
        if !v.isHidden {
          var newHeight: CGFloat
          let min = minimumHeight(v)
          let max = maximumHeight(v)
          if (min == max) {
            newHeight = min
          }
          else {
            newHeight = min + (availableHeight / CGFloat(varHeightCount))
            if (newHeight > max) {
              newHeight = max
            }
          }
          let newFrame = NSMakeRect(0, pos - newHeight, fixedWidth, newHeight)
          let oldFrame = v.frame
          if !NSEqualRects(oldFrame, newFrame) {
            v.frame = newFrame
            changed = true
          }
          pos -= newHeight + _margin
        }
      }
      
      if changed {
        self.needsDisplay = true
      }
    } while (dirty)
    
    updating = false
  }
  
  func minimumHeight(_ view: NSView) -> CGFloat
  {
    if let v = view as? ViewSizeLimits {
      return v.minimumSize().height
    }
    return view.intrinsicContentSize.height
  }
  
  func maximumHeight(_ view: NSView) -> CGFloat
  {
    if let v = view as? ViewSizeLimits {
      return v.maximumSize().height
    }
    return CGFloat(FLT_MAX)
  }
}

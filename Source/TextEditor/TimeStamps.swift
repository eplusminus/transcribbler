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

public class TimeStamps {
  public static let contentType = "time-stamp-text"
  public static let backgroundColor = NSColor.lightGray
  public static let textColor = NSColor.white
  public static let font = NSFont.toolTipsFont(ofSize: NSFont.smallSystemFontSize())
  
  public static func createAttachment(timeString: String) -> NSTextAttachment {
    let cell = TimeStampCell(timeString: timeString)
    let att = NSTextAttachment()
    att.attachmentCell = cell
    if #available(OSX 10.11, *) {
      att.bounds.origin.y = TimeStamps.font.descender
    }
    return att
  }
}

public class TimeStampCell: NSTextAttachmentCell {
  public private(set) var timeString: String
  
  public init(timeString: String) {
    self.timeString = timeString
    super.init()
    
    let style = NSMutableParagraphStyle()
    style.alignment = .center
    let font = TimeStamps.font
    let attrs = [NSParagraphStyleAttributeName: style,
                 NSFontAttributeName: font,
                 NSForegroundColorAttributeName: TimeStamps.textColor]
    let attStr = NSAttributedString(string: timeString, attributes: attrs)
    let textSize = attStr.size()
    let cellSize = NSMakeSize(textSize.width + 8, textSize.height)
    
    let customImage = NSImage(size: cellSize, flipped: false) { r in
      let round = NSBezierPath(roundedRect: r, xRadius: 4, yRadius: 4)
      TimeStamps.backgroundColor.setFill()
      round.fill()
      attStr.draw(in: r)
      return true
    }
    self.image = customImage
    self.isBordered = true
  }
  
  required public init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

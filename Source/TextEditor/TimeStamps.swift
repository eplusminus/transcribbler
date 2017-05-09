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
  public static let timeStampAttribute = "TranscribblerTimeStamp"
  
  public static func createAttributedString(timeString: String) -> NSAttributedString {
    let att = TimeStamps.createAttachment(timeString: timeString)
    let attStr = NSAttributedString(attachment: att)
    let ret = NSMutableAttributedString(attributedString: attStr)
    //ret.addAttribute(timeStampAttribute, value: timeString, range: NSRange(location: 0, length: attStr.length))
    return ret
  }
  
  public static func createAttachment(timeString: String) -> NSTextAttachment {
    let cell = TimeStampCell(timeString: timeString)
    let att = NSTextAttachment()
    att.attachmentCell = cell
    return att
  }
  
  public static func serializeTextToRtfPreservingTimeStamps(_ text: NSAttributedString, documentAttributes: [String: Any]) -> Data? {
    let buf = NSMutableAttributedString(attributedString: text)
    buf.enumerateAttributes(in: NSRange(location: 0, length: text.length), options: .longestEffectiveRangeNotRequired) { (attrs, range, stop) in
      if let ta = attrs[NSAttachmentAttributeName] as? NSTextAttachment {
        if let tsc = ta.attachmentCell as? TimeStampCell {
          let placeholderText = "[TIME=" + tsc.timeString + "]"
          buf.replaceCharacters(in: range, with: NSAttributedString(string: placeholderText))
        }
      }
    }
    return buf.rtf(from: NSRange(location: 0, length: buf.length), documentAttributes: documentAttributes)
  }
  
  public static func deserializeTextFromRtfPreservingTimeStamps(_ rtfData: Data) -> (NSAttributedString, [String: Any])? {
    var attrs: NSDictionary?
    if let src = NSAttributedString(rtf: rtfData, documentAttributes: &attrs) {
      let buf = NSMutableAttributedString(attributedString: src)
      if let regex = try? NSRegularExpression(pattern: "\\[TIME=([0-9:.]*)\\]", options: []) {
        var pos = 0
        while let found = regex.firstMatch(in: buf.string, options: [], range: NSMakeRange(pos, buf.length - pos)) {
          let ts = buf.attributedSubstring(from: found.rangeAt(1)).string
          buf.replaceCharacters(in: found.range, with: TimeStamps.createAttributedString(timeString: ts))
          pos = found.range.location + 1
        }
      }
      return (buf, (attrs ?? NSDictionary()) as! [String: Any])
    }
    return nil
  }
}

public class TimeStampCell: NSTextAttachmentCell {
  public private(set) var timeString: String
  
  public init(timeString: String) {
    self.timeString = timeString
    super.init()
    
    let style = NSMutableParagraphStyle()
    style.alignment = .center
    let attrs = [NSParagraphStyleAttributeName: style,
                 NSFontAttributeName: TimeStamps.font,
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
  }
  
  required public init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

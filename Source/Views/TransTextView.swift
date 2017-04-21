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

import Abbreviations
import Foundation

@objc(TransTextView)
public class TransTextView: NSTextView {
  @IBOutlet var abbrevResolver: AbbrevResolver!
  
  override public func awakeFromNib() {
    self.isRulerVisible = true
  }
  
  override public func keyDown(with event: NSEvent) {
    let chars = (event.characters ?? "").characters
    let ap = AbbrevParser.sharedInstance()
    if chars.count == 1 {
      if let ch = chars.first {
        if ap.isWordTerminator(ch) {
          let r = self.selectedRange()
          if r.length == 0 {
            let pos = r.location
            let currentText = self.textStorage?.string ?? ""
            let lastWord = ap.findPossibleAbbreviation(inString: currentText, beforePos: pos) ?? ""
            if lastWord != "" {
              if let rawExpansion = abbrevResolver.getExpansion(lastWord) {
                let expansion = ap.renderExpansion(rawExpansion, abbreviation: lastWord)
                let r = NSMakeRange(pos - lastWord.characters.count, lastWord.characters.count)
                self.textStorage?.mutableString.replaceCharacters(in: r, with: expansion)
                if let esv = self.enclosingScrollView {
                  self.setNeedsDisplay(esv.contentView.visibleRect)
                }
              }
            }
          }
        }
      }
      self.interpretKeyEvents([event])
    }
  }
}

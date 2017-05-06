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

import Cocoa
import Foundation

@objc(TransDocumentController)
public class TransDocumentController: NSDocumentController {
  
  @IBAction public func openTextDocument(_ sender: AnyObject?) {
    openSomeFile(forTypes: ["public.plain-text", "public.rtf"])
  }
  
  @IBAction public func openAbbreviationList(_ sender: AnyObject?) {
    openSomeFile(forTypes: [AbbrevListDocument.preferredFileType])
  }
  
  private func openSomeFile(forTypes: [String]) {
    let panel = NSOpenPanel()
    panel.allowsMultipleSelection = true
    beginOpenPanel(panel, forTypes: forTypes) { (result) in
      if result == NSFileHandlingPanelOKButton {
        for url in panel.urls {
          self.openDocument(withContentsOf: url, display: true) { _, _, err in
            if let e = err {
              self.presentError(e)
            }
          }
        }
      }
    }
  }
  
  //
  // NSDocumentController
  //
  
  override public func addDocument(_ document: NSDocument) {
    if let ald = document as? AbbrevListDocument {
      if let wc = NSApp.mainWindow?.windowController as? TransTextWindowController {
        wc.abbrevsController.addAbbrevListDocument(ald)
      }
      return
    }
    super.addDocument(document)
  }
}

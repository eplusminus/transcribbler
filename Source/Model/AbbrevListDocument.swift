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

let AbbrevListDocumentModified = "AbbrevListDocumentModified"

class AbbrevListDocument: NSDocument, AbbrevListProvider {
  @IBOutlet private(set) var view: NSView!
  @IBOutlet private(set) var controller: AbbrevArrayController!
  @IBOutlet private(set) var tableView: HandyTableView!
  var abbrevResolver: AbbrevResolverImpl?
  
  func getAbbreviations() -> [AbbrevEntry] {
    if let a = controller?.arrangedObjects as? [AbbrevEntry] {
      return a
    }
    return []
  }
  
  override var windowNibName: String? {
    get {
      return "AbbrevListDocument"
    }
  }
  
  override func windowControllerDidLoadNib(_ aController: NSWindowController) {
    super.windowControllerDidLoadNib(aController)
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
  }

  override func data(ofType: String) throws -> Data {
    // Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
    throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
  }

  override func read(from data: Data, ofType typeName: String) throws {
    // Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
    // If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
    throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
  }

  override class func autosavesInPlace() -> Bool {
    return true
  }
  
  func modified() {
    if let ar = abbrevResolver {
      ar.refresh()
    }
  }
}

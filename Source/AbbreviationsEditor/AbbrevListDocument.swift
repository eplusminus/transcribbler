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
import HelperViews

let AbbrevListDocumentModified = "AbbrevListDocumentModified"
let DefaultAbbrevsKey = "DefaultAbbrevations"

public class AbbrevListDocument: NSDocument, AbbrevListProvider {
  private static var _default: AbbrevListDocument? = nil
  
  @IBOutlet private(set) var controller: NSArrayController!
  public var abbrevResolver: AbbrevResolverImpl?
  
  private var dirty: Bool = false
  
  public static var `default`: AbbrevListDocument {
    get {
      if let d = _default {
        return d
      }
      let ac = NSArrayController()
      if let data = UserDefaults.standard.data(forKey: DefaultAbbrevsKey) {
        do {
          let es = try AbbrevsPlatformEncoding().readAbbrevsFromData(data)
          ac.add(contentsOf: es)
        }
        catch {
        }
      }
      let ar = AbbrevResolverImpl()
      let d = AbbrevListDocument(controller: ac, resolver: ar)
      ar.addProvider(d)
      ar.refresh()
      _default = d
      return d
    }
  }

  private init(controller: NSArrayController, resolver: AbbrevResolverImpl) {
    super.init()
    self.controller = controller
    self.abbrevResolver = resolver
    controller.addObserver(self, forKeyPath: "arrangedObjects", options: [], context: nil)
  }
  
  override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    modified()
  }
  
  public func getAbbreviations() -> [AbbrevEntry] {
    return (controller?.arrangedObjects as? [AbbrevEntry]) ?? []
  }
  
  override public var windowNibName: String? {
    get {
      return "AbbrevListDocument"
    }
  }
  
  override public func windowControllerDidLoadNib(_ aController: NSWindowController) {
    super.windowControllerDidLoadNib(aController)
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
  }

  override public func data(ofType: String) throws -> Data {
    // Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
    throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
  }

  override public func read(from data: Data, ofType typeName: String) throws {
    // Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
    // If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
    throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
  }

  override public class func autosavesInPlace() -> Bool {
    return true
  }
  
  private func modified() {
    if !OSAtomicTestAndSet(0, &dirty) {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.processChanges() }
    }
  }

  /**
   * Ensures that any necessary internal updates have been done (re-indexing the lookup table,
   * auto-saving, etc.) to take recent edits into account.  These are normally deferred a little
   * for performance reasons.
   */
  public func processChanges() {
    if OSAtomicTestAndClear(0, &dirty) {
      if let ar = abbrevResolver {
        ar.refresh()
      }
      persist()
    }
  }
  
  private func persist() {
    if let data = AbbrevsPlatformEncoding().writeAbbrevsToData(getAbbreviations()) {
      UserDefaults.standard.set(data, forKey: DefaultAbbrevsKey)
      NSLog("persisted")
    }
  }
}

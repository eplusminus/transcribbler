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
import HelperViews

import Cocoa
import Foundation

let AbbrevListDocumentModified = "AbbrevListDocumentModified"

@objc(AbbrevListDocument)
public class AbbrevListDocument: NSDocument, AbbrevListProvider {
  private static let DefaultAbbrevsKey = "DefaultAbbreviations"
  private static var _default: AbbrevListDocument? = nil
  
  @IBOutlet private(set) var controller: NSArrayController!

  public var abbrevResolver: AbbrevResolverImpl?
  
  public private(set) var isDefaultList: Bool = false
  
  private var dirty: Bool = false
  private var ignoreChanges: Bool = false
  private var encoding = AbbrevsPlatformEncoding()
  
  public static var preferredFileType: String {
    get {
      return "net.errorbar.transcribbler.table"
    }
  }
  
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
      d.isDefaultList = true
      ar.addProvider(d)
      d.displayName = NSLocalizedString("MainAbbrevList", comment: "")
      _default = d
      return d
    }
  }

  override public convenience init() {
    self.init(controller: NSArrayController(), resolver: AbbrevListDocument.default.abbrevResolver!)
    self.displayName = NSLocalizedString("NewAbbrevList", comment: "")
  }
  
  private init(controller: NSArrayController, resolver: AbbrevResolverImpl) {
    super.init()
    
    self.controller = controller
    self.abbrevResolver = resolver
    controller.addObserver(self, forKeyPath: "arrangedObjects", options: [], context: nil)
    
    self.fileType = AbbrevListDocument.preferredFileType
  }
  
  override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    if !ignoreChanges {
      modified()
    }
  }
  
  public func getAbbreviations() -> [AbbrevEntry] {
    return (controller?.arrangedObjects as? [AbbrevEntry]) ?? []
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
    if fileURL != nil {
      save(nil)
    }
    else if isDefaultList {
      let data = AbbrevsPlatformEncoding().writeAbbrevsToData(getAbbreviations())
      UserDefaults.standard.set(data, forKey: AbbrevListDocument.DefaultAbbrevsKey)
    }
  }
  
  //
  // NSDocument
  //
  
  override public func read(from data: Data, ofType typeName: String) throws {
    let es = try encoding.readAbbrevsFromData(data)
    ignoreChanges = true
    defer {
      ignoreChanges = false
    }
    controller.remove(atArrangedObjectIndexes: IndexSet(integersIn: 0..<getAbbreviations().count))
    controller.add(contentsOf: es)
  }
  
  override public func data(ofType typeName: String) throws -> Data {
    return encoding.writeAbbrevsToData(getAbbreviations())
  }
}

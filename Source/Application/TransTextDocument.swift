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
import AbbreviationsEditor

import Cocoa
import Foundation

let windowPosCommentParam = "WindowPos"
let mediaFilePathCommentParam = "MediaFile"
let timeCodeCommentParam = "TimeCode"
let mediaDrawerOpenCommentParam = "MediaDrawerOpen"
let abbrevDrawerOpenCommentParam = "AbbrevDrawerOpen"

@objc(TransTextDocument)
public class TransTextDocument: NSDocument {
  var windowController: TransTextWindowController!
  
  var textStorage: NSTextStorage?
  var abbrevListDocument: AbbrevListDocument
  var abbrevResolver: AbbrevResolverImpl
  
  var loadedText: NSAttributedString?
  var loadedDocAttributes: NSDictionary?
  
  public override init() {
    abbrevListDocument = AbbrevListDocument()
    abbrevResolver = AbbrevResolverImpl()
    abbrevResolver.addProvider(abbrevListDocument)
    abbrevListDocument.abbrevResolver = abbrevResolver
  }

  override public func makeWindowControllers() {
    let wc = TransTextWindowController(windowNibName: "TransTextDocument")
    windowController = wc
    addWindowController(wc)
  }
  
  override public func windowControllerDidLoadNib(_ wc: NSWindowController) {
    super.windowControllerDidLoadNib(wc)
    
    textStorage = windowController.textView.textStorage
    
    windowController.abbrevsController.addAbbrevListDocument(abbrevListDocument)
    windowController.textView.abbrevResolver = abbrevResolver
    
    useLoadedText()
  }
  
  override public func read(from file: FileWrapper, ofType typeName: String) throws {
    if let rtf = file.regularFileContents {
      loadedText = NSAttributedString(rtf: rtf, documentAttributes: &loadedDocAttributes)
//      if loadedText != nil {
//        useLoadedText()
//      }
    }
  }
  
  override public func fileWrapper(ofType typeName: String) throws -> FileWrapper {
    let attrs = makeDocAttributes()
    let data = textStorage!.rtf(from: NSMakeRange(0, textStorage!.string.characters.count), documentAttributes: attrs)
    return FileWrapper(regularFileWithContents: data!)
  }

  //
  // internal
  //
  
  private func useLoadedText() {
    if let t = textStorage {
      if let lt = loadedText {
        t.replaceCharacters(in: NSMakeRange(0, t.characters.count), with: lt)
        loadedText = nil
      }
    }
    if let lda = loadedDocAttributes {
      readDocAttributes(lda)
      loadedDocAttributes = nil
    }
  }
  
  private func readDocAttributes(_ attrs: NSDictionary) {
    let paramsString = (attrs.object(forKey: NSCommentDocumentAttribute) as? String) ?? ""
    let (commentParams, _) = CommentStringFields.paramsFromString(paramsString)
    
    if let wp = commentParams[windowPosCommentParam] {
      let r = NSRectFromString(wp)
      if r.size.width > 0 {
        windowController.window?.setFrame(r, display: true)
      }
    }
  
    let mc = windowController.mediaController
    
    if let mfp = commentParams[mediaFilePathCommentParam] {
      do {
        try mc?.openMediaFile(filePath: mfp)
      }
      catch {
      }
    }
    
    if let tc = commentParams[timeCodeCommentParam] {
      mc?.timeCodeString = tc
    }
    
    if let _ = commentParams[mediaDrawerOpenCommentParam] {
      windowController.mediaDrawerOpen = true
    }
    
    if let _ = commentParams[abbrevDrawerOpenCommentParam] {
      windowController.abbrevDrawerOpen = true
    }
  }
  
  private func makeDocAttributes() -> [String: String] {
    var attrs: [String: String] = [NSDocumentTypeDocumentAttribute: NSRTFTextDocumentType]
    var commentParams: [String: String] = [:]
    let mc = windowController.mediaController
    
    if let wf = windowController.window?.frame {
      commentParams[windowPosCommentParam] = NSStringFromRect(wf)
    }
    if let mfp = mc?.mediaFilePath {
      commentParams[mediaFilePathCommentParam] = mfp
    }
    if let tc = mc?.timeCodeString {
      commentParams[timeCodeCommentParam] = tc
    }
    if windowController.mediaDrawerOpen {
      commentParams[mediaDrawerOpenCommentParam] = ""
    }
    if windowController.abbrevDrawerOpen {
      commentParams[abbrevDrawerOpenCommentParam] = ""
    }
    
    let comment = CommentStringFields.stringFromParams(commentParams)
    if comment != "" {
      attrs[NSCommentDocumentAttribute] = comment
    }
    return attrs
  }
}

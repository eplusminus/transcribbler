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
import Media

import Cocoa
import Foundation

let windowPosCommentParam = "WindowPos"
let mediaFilePathCommentParam = "MediaFile"
let timeCodeCommentParam = "TimeCode"
let timeCodeOffsetSubtractCommentParam = "TimeCodeOffsetSubtract"
let timeCodeOffsetAddCommentParam = "TimeCodeOffsetAdd"

@objc(TransTextDocument)
public class TransTextDocument: NSDocument {
  var windowController: TransTextWindowController!
  
  var textStorage: NSTextStorage?
  var abbrevResolver: AbbrevResolverImpl
  
  var loadedText: NSAttributedString?
  var loadedDocAttributes: [String: Any]?
  
  public static var preferredFileType: String {
    get {
      return "net.errorbar.transcribbler.rtf"
    }
  }
  
  public override init() {
    abbrevResolver = AbbrevListDocument.default.abbrevResolver!
  }

  override public func makeWindowControllers() {
    let wc = TransTextWindowController(windowNibName: "TransTextDocument")
    windowController = wc
    addWindowController(wc)
  }
  
  override public func windowControllerDidLoadNib(_ wc: NSWindowController) {
    super.windowControllerDidLoadNib(wc)
    
    textStorage = windowController.textView.textStorage
    
    windowController.textView.abbrevResolver = abbrevResolver
    
    useLoadedText()
  }
  
  override public func read(from data: Data, ofType typeName: String) throws {
    if typeName == "public.plain-text" {
      if let s = String(data: data, encoding: .utf8) {
        loadedText = NSAttributedString(string: s)
      }
    }
    else {
      if let (text, attrs) = TimeStamps.deserializeTextFromRtfPreservingTimeStamps(data) {
        loadedText = text
        loadedDocAttributes = attrs
      }
    }
  }
  
  override public func data(ofType typeName: String) throws -> Data {
    if typeName == "public.plain-text" {
      return textStorage!.string.data(using: .utf8)!
    }
    else {
      let attrs = makeDocAttributes()
      let data = TimeStamps.serializeTextToRtfPreservingTimeStamps(textStorage!, documentAttributes: attrs)
      return data!
    }
  }

  //
  // internal
  //
  
  private func useLoadedText() {
    if let t = textStorage {
      if let lt = loadedText {
        t.setAttributedString(lt)
        loadedText = nil
      }
    }
    if let lda = loadedDocAttributes {
      readDocAttributes(lda)
      loadedDocAttributes = nil
    }
  }
  
  private func readDocAttributes(_ attrs: [String: Any]) {
    let paramsString = (attrs[NSCommentDocumentAttribute] as? String) ?? ""
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
    
    mc?.timeCodeOffsetSubtract = commentParams[timeCodeOffsetSubtractCommentParam].flatMap { MediaController.timeFromString($0) }.map { TimeWrapper($0) }
    mc?.timeCodeOffsetAdd = commentParams[timeCodeOffsetAddCommentParam].flatMap { MediaController.timeFromString($0) }.map { TimeWrapper($0) }

    mc?.timeCodeString = commentParams[timeCodeCommentParam]
  }
  
  private func makeDocAttributes() -> [String: String] {
    var attrs: [String: String] = [NSDocumentTypeDocumentAttribute: TransTextDocument.preferredFileType]
    var commentParams: [String: String] = [:]
    let mc = windowController.mediaController
    
    addParam(&commentParams, windowController.window?.frame, windowPosCommentParam) { NSStringFromRect($0) }
    addParam(&commentParams, mc?.mediaFilePath, mediaFilePathCommentParam) { $0 }
    addParam(&commentParams, mc?.timeCodeString, timeCodeCommentParam) { $0 }
    addParam(&commentParams, mc?.timeCodeOffsetSubtract, timeCodeOffsetSubtractCommentParam) { MediaController.timeString($0.value, withFractions: false) }
    addParam(&commentParams, mc?.timeCodeOffsetAdd, timeCodeOffsetAddCommentParam) { MediaController.timeString($0.value, withFractions: false) }
    
    let comment = CommentStringFields.stringFromParams(commentParams)
    if comment != "" {
      attrs[NSCommentDocumentAttribute] = comment
    }
    return attrs
  }
  
  private func addParam<T>(_ commentParams: inout [String: String], _ optValue: T?, _ key: String, _ transform: (T) -> String) {
    if let value = optValue {
      commentParams[key] = transform(value)
    }
  }
}

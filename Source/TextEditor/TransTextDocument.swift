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
    let dp = DocPreferences.deserializeFromStrings(commentParams)
    
    if let r = dp.windowPos {
      windowController.window?.setFrame(r, display: true)
    }
  
    if let mc = windowController.mediaController {
      if let mfp = dp.mediaFilePath {
        do {
          try mc.openMediaFile(filePath: mfp)
        }
        catch {
        }
      }
      mc.timeCodeOffsetSubtract = dp.timeCodeOffsetSubtract
      mc.timeCodeOffsetAdd = dp.timeCodeOffsetAdd
      mc.timeCodeString = dp.timeCodeString
      if let prp = dp.playbackRatePercent {
        mc.playbackRatePercent = prp
      }
    }
  }
  
  private func makeDocAttributes() -> [String: String] {
    var attrs: [String: String] = [NSDocumentTypeDocumentAttribute: TransTextDocument.preferredFileType]
    let dp = DocPreferences()
    dp.windowPos = windowController.window?.frame
    if let mc = windowController.mediaController {
      dp.mediaFilePath = mc.mediaFilePath
      dp.timeCodeString = mc.timeCodeString
      dp.timeCodeOffsetSubtract = mc.timeCodeOffsetSubtract
      dp.timeCodeOffsetAdd = mc.timeCodeOffsetAdd
      dp.playbackRatePercent = mc.playbackRatePercent
    }
    let comment = CommentStringFields.stringFromParams(dp.serializeToStrings())
    if comment != "" {
      attrs[NSCommentDocumentAttribute] = comment
    }
    return attrs
  }
}

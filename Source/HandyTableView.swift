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

@objc(HandyTableView)
public class HandyTableView: NSTableView {
  @IBOutlet public var backTabDestination: NSView?
  @IBOutlet public var forwardTabDestination: NSView?
  
  private var myClickedCol: NSInteger = -1
  private var myClickedRow: NSInteger = -1
  private var editing: Bool = false
  private var tabWrapsForward: Bool = false
  private var tabWrapsBackward: Bool = false
  private var fieldEditor: QuickTableTextView = QuickTableTextView()
  
  override public init(frame: NSRect) {
    super.init(frame: frame)
    fieldEditor.tableView = self
  }
  
  required public init?(coder: NSCoder) {
    super.init(coder: coder)
    fieldEditor.tableView = self
  }
  
  public func add(_ sender: Any?) {
  }

  //
  // NSTableView
  //
  
  override public func textDidEndEditing(_ notification: Notification) {
    editing = false
    super.textDidEndEditing(notification)
  }
  
  //
  // to be used from a NSWindowDelegate implementation
  //
  
  public class func windowWillReturnFieldEditor(_ sender: NSWindow, toObject: AnyObject) -> AnyObject? {
    if let htv = toObject as? HandyTableView {
      return htv.fieldEditor
    }
    return nil
  }
  
  //
  // NSResponder
  //
  
  override public func mouseDown(with event: NSEvent) {
    myClickedRow = -1
    myClickedCol = -1
    if event.clickCount > 1 && editing {
      currentEditor()?.mouseDown(with: event)
    }
    else if event.modifierFlags.contains(NSEventModifierFlags.shift) ||
            event.modifierFlags.contains(NSEventModifierFlags.command) {
      super.mouseDown(with: event)
    }
    else {
      let loc = self.convert(event.locationInWindow, from: nil)
      let col = self.column(at: loc)
      let row = self.row(at: loc)
      if row >= 0 {
        if self.selectedRow != row || self.editedColumn != col {
          validateEditing()
          abortEditing()
          selectRow(row)
          myClickedRow = row
          myClickedCol = col
        }
      }
      else {
        if !(handyDelegate()?.tableViewClickedBelowLastRow(self, point: loc) ?? false) {
          super.mouseDown(with: event)
        }
      }
    }
  }
  
  override public func mouseDragged(with event: NSEvent) {
    if myClickedRow < 0 {
      super.mouseDragged(with: event)
    }
    else {
      let loc = self.convert(event.locationInWindow, from: nil)
      let row = self.row(at: loc)
      let rowStart = (row < myClickedRow) ? row : myClickedRow
      let rowEnd = (row < myClickedRow) ? myClickedRow : row
      
      scrollRowToVisible(row)
      selectRowIndexes(IndexSet(integersIn: rowStart...rowEnd), byExtendingSelection: false)
    }
  }
  
  override public func mouseUp(with event: NSEvent) {
    if !event.modifierFlags.contains(NSEventModifierFlags.shift) &&
       !event.modifierFlags.contains(NSEventModifierFlags.command) {
      let loc = self.convert(event.locationInWindow, from: nil)
      let col = self.column(at: loc)
      let row = self.row(at: loc)
      if row >= 0 {
        if selectedRowIndexes.count == 1 && myClickedRow == row && myClickedCol == col {
          editColumn(col, row: row, with: nil, select: false)
          if let field = currentEditor() as? NSTextView {
            let fieldLoc = field.convert(event.locationInWindow, from: nil)
            let pos = field.characterIndexForInsertion(at: fieldLoc)
            field.setSelectedRange(NSMakeRange(pos, 0))
            editing = true
            return
          }
        }
      }
      super.mouseUp(with: event)
    }
  }

  internal func handyDelegate() -> HandyTableViewDelegate? {
    return self.delegate as? HandyTableViewDelegate
  }
  
  internal func selectRow(_ row: NSInteger) {
    selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
  }
}

@objc public protocol HandyTableViewDelegate {
  func tableViewCanDeleteEmptyRow(_ view: HandyTableView, row: NSInteger) -> Bool
  func tableViewClickedBelowLastRow(_ view: HandyTableView, point: NSPoint) -> Bool
}

//
// Specialized text view used as a field editor for this table
//

internal class QuickTableTextView: NSTextView {
  var tableView: HandyTableView!
  private var movedVerticallyAtCharPos: NSInteger = NSNotFound
  private var movedVerticallyAtPixelPos: CGFloat = 0
  
  //
  //	NSTextView
  //

  override public func setSelectedRange(_ charRange: NSRange, affinity: NSSelectionAffinity, stillSelecting flag: Bool) {
    super.setSelectedRange(charRange, affinity: affinity, stillSelecting: flag)
    movedVerticallyAtCharPos = NSNotFound
  }
  
  //
  //	NSResponder
  //
  
  override public func keyDown(with event: NSEvent) {
    if let ch = event.characters?.unicodeScalars.first {
      let ci = Int(ch.value)
      let row = tableView.editedRow
      if ci == NSTabCharacter {
        let col = tableView.editedColumn + 1
        if col == tableView.numberOfColumns {
          if let ftd = tableView.forwardTabDestination {
            tableView.window?.makeFirstResponder(ftd)
          }
          else {
            if row == tableView.numberOfRows - 1 {
              insertNewline(nil)
            }
            else {
              tableView.selectRow(row + 1)
              tableView.editColumn(0, row: row + 1, with: nil, select: false)
            }
          }
        }
        else {
          tableView.editColumn(col, row: row, with: nil, select: false)
        }
      }
      else if ci == NSBackTabCharacter {
        let col = tableView.editedColumn - 1
        if col < 0 {
          if let btd = tableView.backTabDestination {
            tableView.window?.makeFirstResponder(btd)
          }
          else {
            if row > 0 {
              tableView.selectRow(row - 1)
              tableView.editColumn(tableView.numberOfColumns - 1, row: row - 1, with: nil, select: false)
            }
          }
        }
        else {
          tableView.editColumn(col, row: row, with: nil, select: false)
        }
      }
      else {
        super.keyDown(with: event)
      }
    }
  }
  
  override public func deleteBackward(_ sender: Any?) {
    let r = selectedRange()
    if r.location > 0 || r.length > 0 || (self.string?.characters.count ?? 0) > 0 {
      super.deleteBackward(sender)
      return
    }
    let row = tableView.editedRow
    let col = tableView.editedColumn
    if col == 0 {
      if row > 0 {
        tableView.validateEditing()
        tableView.abortEditing()
        if tableView.handyDelegate()?.tableViewCanDeleteEmptyRow(tableView, row: row) ?? false {
          self.window?.makeFirstResponder(tableView)
          tableView.selectRow(row)
          NSApplication.shared().sendAction(#selector(delete), to: tableView.delegate, from: self)
        }
        tableView.selectRow(row - 1)
        tableView.editColumn(tableView.numberOfColumns - 1, row: row - 1, with: nil, select: false)
        if let e = tableView.currentEditor() {
          e.selectedRange = NSMakeRange(e.string?.characters.count ?? 0, 0)
        }
        return
      }
    }
    moveLeft(sender)
  }
  
  override public func moveLeft(_ sender: Any?) {
    let r = selectedRange()
    if r.location > 0 || r.length > 0 {
      super.moveLeft(sender)
      return
    }
    let row = tableView.editedRow
    let col = tableView.editedColumn
    if col == 0 {
      if row == 0 {
        return
      }
      tableView.deselectAll(self)
      tableView.selectRow(row - 1)
      tableView.editColumn(tableView.numberOfColumns - 1, row: row - 1, with: nil, select: false)
    }
    else {
      tableView.deselectAll(self)
      tableView.selectRow(row)
      tableView.editColumn(col - 1, row: row, with: nil, select: false)
    }
    moveInsertionPointToStartOrEnd(end: true)
    movedVerticallyAtCharPos = NSNotFound
  }

  override public func moveRight(_ sender: Any?) {
    let r = selectedRange()
    if r.location < (string?.characters.count ?? 0) || r.length > 0 {
      super.moveRight(sender)
      return
    }
    let row = tableView.editedRow
    let col = tableView.editedColumn + 1
    if col == tableView.numberOfColumns {
      if row == tableView.numberOfRows - 1 {
        return
      }
      tableView.deselectAll(self)
      tableView.selectRow(row + 1)
      tableView.editColumn(0, row: row + 1, with: nil, select: false)
    }
    else {
      tableView.deselectAll(self)
      tableView.selectRow(row)
      tableView.editColumn(col, row: row, with: nil, select: false)
    }
    moveInsertionPointToStartOrEnd(end: false)
    movedVerticallyAtCharPos = NSNotFound
  }
  
  override public func moveUp(_ sender: Any?) {
    let row = tableView.editedRow - 1
    if row >= 0 {
      moveVerticallyToRow(row)
    }
  }
  
  override public func moveDown(_ sender: Any?) {
    let row = tableView.editedRow + 1
    if row < tableView.numberOfRows {
      moveVerticallyToRow(row)
    }
  }
  
  override public func insertNewline(_ sender: Any?) {
    window?.makeFirstResponder(tableView)
    NSApplication.shared().sendAction(#selector(HandyTableView.add), to: nil, from: self)
  }
  
  private func getSelectionPixelPos() -> CGFloat {
    if let lm = layoutManager {
      if let tc = textContainer {
        let r = lm.glyphRange(forCharacterRange: selectedRange(), actualCharacterRange: nil)
        let bounds = lm.boundingRect(forGlyphRange: r, in: tc)
        return bounds.origin.x
      }
    }
    return -1
  }
  
  private func setSelectionPixelPos(_ pos: CGFloat) {
    let p = characterIndexForInsertion(at: NSMakePoint(pos, 1))
    setSelectedRange(NSMakeRange(p, 0))
  }
  
  private func moveInsertionPointToStartOrEnd(end: Bool) {
    if let e = tableView.currentEditor() {
      e.selectedRange = NSMakeRange(end ? (string?.characters.count ?? 0) : 0, 0)
    }
  }
  
  private func moveVerticallyToRow(_ row: NSInteger) {
    let r = selectedRange()
    let col = tableView.editedColumn
    var pos: CGFloat
    if r.length == 0 && r.location == movedVerticallyAtCharPos {
      pos = movedVerticallyAtPixelPos
    }
    else {
      pos = getSelectionPixelPos()
      movedVerticallyAtPixelPos = pos
    }
    tableView.selectRow(row)
    tableView.editColumn(col, row: row, with: nil, select: false)
    setSelectionPixelPos(pos)
    movedVerticallyAtCharPos = selectedRange().location
  }
}

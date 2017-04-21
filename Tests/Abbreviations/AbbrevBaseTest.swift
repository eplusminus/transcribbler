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
import XCTest

class AbbrevBaseTest: XCTestCase {
  func testDefaultAbbreviationIsEmpty() {
    XCTAssertEqual("", AbbrevBase().abbreviation)
  }
  
  func testDefaultExpansionIsEmpty() {
    XCTAssertEqual("", AbbrevBase().expansion)
  }
  
  func testInitWithPropertiesSetsAbbreviation() {
    XCTAssertEqual("d", AbbrevBase(abbreviation: "d", expansion: "dog").abbreviation)
  }
  
  func testInitWithPropertiesSetsExpansion() {
    XCTAssertEqual("dog", AbbrevBase(abbreviation: "d", expansion: "dog").expansion)
  }
  
  func testSetAbbreviation() {
    let e = AbbrevBase()
    e.abbreviation = "d"
    XCTAssertEqual("d", e.abbreviation)
  }
  
  func testSetExpansion() {
    let e = AbbrevBase()
    e.expansion = "dog"
    XCTAssertEqual("dog", e.expansion)
  }
  
  func testDefaultIsEmpty() {
    XCTAssertTrue(AbbrevBase().isEmpty())
  }
  
  func testIsNotEmptyWithAbbreviation() {
    XCTAssertFalse(AbbrevBase(abbreviation: "d", expansion: "").isEmpty())
  }
  
  func testIsNotEmptyWithExpansion() {
    XCTAssertFalse(AbbrevBase(abbreviation: "", expansion: "dog").isEmpty())
  }
}

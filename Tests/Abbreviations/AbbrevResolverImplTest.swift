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

class SimpleAbbrevListProvider: AbbrevListProvider {
  var items: [AbbrevEntry]
  
  init(_ items: [AbbrevEntry]) {
    self.items = items
  }
  
  func getAbbreviations() -> [AbbrevEntry] {
    return items
  }
}

class AbbrevResolverImplTest: XCTestCase {

  var resolver = AbbrevResolverImpl()
  var simpleEntry = AbbrevEntry(abbreviation: "dog", expansion: "cat")
  var suffixEntry = AbbrevEntry(abbreviation: "d", expansion: "dog",
                                variants: [AbbrevBase(abbreviation: "s", expansion: "es")])
  
  func testResolverWithNoProvidersFindsNothing() {
    XCTAssertNil(resolver.getExpansion("dog"))
  }
  
  func testResolverFindsAbbreviationFromSimpleEntry() {
    resolver.addProvider(SimpleAbbrevListProvider([simpleEntry]))
    XCTAssertEqual("cat", resolver.getExpansion("dog"))
  }
  
  func testResolverFindsAbbreviationFromEntryWithSuffix() {
    resolver.addProvider(SimpleAbbrevListProvider([suffixEntry]))
    XCTAssertEqual("doges", resolver.getExpansion("ds"))
  }
}

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

class AbbrevsTextEncodingTest: XCTestCase {

  let sVariant = AbbrevBase(abbreviation: "s", expansion: "s")
  let sesVariant = AbbrevBase(abbreviation: "s", expansion: "es")
  let ingVariantDoubling = AbbrevBase(abbreviation: "g", expansion: ">ing")
  
  let encoding = AbbrevsTextEncoding()
  
  private func makeTestAbbrevs() -> [AbbrevEntry] {
    return [AbbrevEntry(abbreviation: "c", expansion: "cat", variants: [sVariant]),
      AbbrevEntry(abbreviation: "d", expansion: "dog")]
  }
  
  func testPasteboardType() {
    XCTAssertEqual("public.utf8-plain-text", encoding.pasteboardType())
  }
  
  func testSerialization() {
    let d = encoding.writeAbbrevsToData(makeTestAbbrevs())
    let s = String(data: d!, encoding: String.Encoding.utf8)
    XCTAssertEqual("c\tcat~s\nd\tdog\n", s)
  }
  
  func testDeserialization() throws {
    let d = "c\tcat~s\nd\tdog\n".data(using: String.Encoding.utf8)!
    let abs = try encoding.readAbbrevsFromData(d)
    XCTAssertEqual(makeTestAbbrevs(), abs)
  }
  
  func testFormatExpansionNoVariants() {
    XCTAssertEqual("dog", AbbrevsTextEncoding.formatExpansion("dog", nil))
  }

  func testFormatExpansionEmptyVariants() {
    XCTAssertEqual("dog", AbbrevsTextEncoding.formatExpansion("dog", []))
  }

  func testFormatExpansionMinimalVariant() {
    XCTAssertEqual("dog~s", AbbrevsTextEncoding.formatExpansion("dog", [sVariant]))
  }
  
  func testFormatExpansionBasicVariant() {
    XCTAssertEqual("dog~s=es", AbbrevsTextEncoding.formatExpansion("dog", [sesVariant]))
  }
  
  func testFormatExpansionMultiVariants() {
    XCTAssertEqual("dog~s=es g=>ing", AbbrevsTextEncoding.formatExpansion("dog", [sesVariant, ingVariantDoubling]))
  }

  func testParseExpansionNoVariantsReturnsExpansion() {
    let (ex, _) = AbbrevsTextEncoding.parseExpansionAndVariants("dog")
    XCTAssertEqual("dog", ex)
  }

  func testParseExpansionNoVariantsReturnsNoVariants() {
    let (_, vs) = AbbrevsTextEncoding.parseExpansionAndVariants("dog")
    XCTAssertNil(vs)
  }
  
  func testParseExpansionWithMinimalVariantReturnsExpansion() {
    let (ex, _) = AbbrevsTextEncoding.parseExpansionAndVariants("dog~s")
    XCTAssertEqual("dog", ex)
  }
  
  func testParseExpansionWithMinimalVariantReturnsVariantWithAbbreviation() {
    let (_, vs) = AbbrevsTextEncoding.parseExpansionAndVariants("dog~s")
    XCTAssertEqual("s", vs![0].abbreviation)
  }

  func testParseExpansionWithMinimalVariantReturnsVariantWithExpansion() {
    let (_, vs) = AbbrevsTextEncoding.parseExpansionAndVariants("dog~s")
    XCTAssertEqual("s", vs![0].expansion)
  }
  
  func testParseExpansionWithBasicVariantReturnsExpansion() {
    let (ex, _) = AbbrevsTextEncoding.parseExpansionAndVariants("dog~s=es")
    XCTAssertEqual("dog", ex)
  }
  
  func testParseExpansionWithBasicVariantReturnsVariantWithAbbreviation() {
    let (_, vs) = AbbrevsTextEncoding.parseExpansionAndVariants("dog~s=es")
    XCTAssertEqual("s", vs![0].abbreviation)
  }
  
  func testParseExpansionWithBasicVariantReturnsVariantWithExpansion() {
    let (_, vs) = AbbrevsTextEncoding.parseExpansionAndVariants("dog~s=es")
    XCTAssertEqual("es", vs![0].expansion)
  }
  
  func testParseExpansionWithTwoVariantsReturnsExpansion() {
    let (ex, _) = AbbrevsTextEncoding.parseExpansionAndVariants("dog~s=es g=ing")
    XCTAssertEqual("dog", ex)
  }
  
  func testParseExpansionWithTwoVariantsReturnsVariantWithAbbreviation() {
    let (_, vs) = AbbrevsTextEncoding.parseExpansionAndVariants("dog~s=es g=ing")
    XCTAssertEqual("g", vs![1].abbreviation)
  }
  
  func testParseExpansionWithTwoVariantsReturnsVariantWithExpansion() {
    let (_, vs) = AbbrevsTextEncoding.parseExpansionAndVariants("dog~s=es g=ing")
    XCTAssertEqual("ing", vs![1].expansion)
  }
}

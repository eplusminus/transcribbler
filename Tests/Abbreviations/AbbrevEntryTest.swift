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

class AbbrevEntryTest: XCTestCase {

  let dogAbbrev = AbbrevEntry(abbreviation: "d", expansion: "dog")
  let letAbbrev = AbbrevEntry(abbreviation: "l", expansion: "let")
  let loveAbbrev = AbbrevEntry(abbreviation: "l", expansion: "love")
  let sVariant = AbbrevBase(abbreviation: "s", expansion: "s")
  let sesVariant = AbbrevBase(abbreviation: "s", expansion: "es")
  let ingVariantBackspace = AbbrevBase(abbreviation: "g", expansion: "<ing")
  let ingVariantDoubling = AbbrevBase(abbreviation: "g", expansion: ">ing")
  
  func testDefaultNoVariants() {
    XCTAssertNil(AbbrevEntry().variants)
  }

  func testVariantAbbreviation() {
    XCTAssertEqual("ds", dogAbbrev.variantAbbreviation(sesVariant))
  }
  
  func testVariantExpansionSimple() {
    XCTAssertEqual("doges", dogAbbrev.variantExpansion(sesVariant))
  }
  
  func testVariantExpansionWithBackspace() {
    XCTAssertEqual("loving", loveAbbrev.variantExpansion(ingVariantBackspace))
  }
  
  func testVariantExpansionWithDoubling() {
    XCTAssertEqual("letting", letAbbrev.variantExpansion(ingVariantDoubling))
  }
  
  func testObserverForAbbreviation() {
    let obs = AbbrevEntryTestObserverStub()
    dogAbbrev.addObserver(obs, forKeyPath: "abbreviation", options: [], context: nil)
    dogAbbrev.abbreviation = "cat"
    dogAbbrev.setValue("catt", forKeyPath: "abbreviation")
    XCTAssertEqual(["abbreviation"], obs.receivedKeyPaths)
  }
}

class AbbrevEntryTestObserverStub: NSObject {
  var receivedKeyPaths: [String] = []
  var receivedObjects: [Any] = []
  
  override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    receivedKeyPaths.append(keyPath ?? "")
    receivedObjects.append(object ?? self)
  }
}

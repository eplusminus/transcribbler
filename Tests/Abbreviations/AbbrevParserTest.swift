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

class AbbrevParserTest: XCTestCase {

  var parser = AbbrevParser()
  
  func testFindPossibleAbbreviationNoTerminator() {
    XCTAssertEqual("dog", parser.findPossibleAbbreviation(inString: "dog", beforePos: 3))
  }
  
  func testFindPossibleAbbreviationWordTerminator() {
    XCTAssertEqual("cat", parser.findPossibleAbbreviation(inString: "dog cat", beforePos: 7))
  }

  func testFindPossibleAbbreviationSingleQuoteIsNotTerminatorInsideWord() {
    XCTAssertEqual("dog's", parser.findPossibleAbbreviation(inString: "dog's", beforePos: 5))
  }

  func testFindPossibleAbbreviationSingleQuoteIsTerminatorBeforeWord() {
    XCTAssertEqual("cat", parser.findPossibleAbbreviation(inString: "dog 'cat", beforePos: 8))
  }

  func testFindPossibleAbbreviationSingleQuoteIsTerminatorAtStart() {
    XCTAssertEqual("cat", parser.findPossibleAbbreviation(inString: "'cat", beforePos: 4))
  }

  func testRenderExpansionNotCapitalized() {
    XCTAssertEqual("dog", parser.renderExpansion("dog", abbreviation: "do"))
  }
  
  func testRenderExpansionInitialCap() {
    XCTAssertEqual("Dog", parser.renderExpansion("dog", abbreviation: "Do"))
  }
  
  func testRenderExpansionAllCaps() {
    XCTAssertEqual("DOG", parser.renderExpansion("dog", abbreviation: "DO"))
  }
  
  func testRenderExpansionInitialCapSingleLetter() {
    XCTAssertEqual("Dog", parser.renderExpansion("dog", abbreviation: "D"))
  }
}

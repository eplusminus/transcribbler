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

import Foundation

struct CommonSuffixRule {
  var abbreviation: String
  var choices: [CommonSuffixChoice]
}

struct CommonSuffixChoice {
  var expansion: String
  var preferredEndings: [String]
  var preferredRegexes: [NSRegularExpression]
  
  func matches(_ s: String) -> Bool {
    let r = NSRange(location: 0, length: s.characters.count)
    let m: (NSRegularExpression) -> Bool = { rx in
      rx.numberOfMatches(in: s, options: [], range: r) > 0 }
    return preferredRegexes.count > 0 && preferredRegexes.contains(where: m)
  }
}

public class CommonSuffixes {
  private static let DefaultSuffixesKey = "CommonSuffixes"
  
  static var defaultRules: [CommonSuffixRule] {
    get {
      if let rs = _defaultRules {
        return rs
      }
      // try to load from user defaults
      var rs: [CommonSuffixRule] = []
      for item in UserDefaults.standard.array(forKey: DefaultSuffixesKey) ?? [] {
        let ss = ((item as? String) ?? "").components(separatedBy: " ")
        if ss.count >= 2 {
          let abbr = ss[0]
          let exp = ss[1]
          let ends = (ss.count > 2) ? Array(ss.dropFirst(2)) : []
          let regs = ends.flatMap { try? NSRegularExpression(pattern: $0 + "$", options: [.caseInsensitive]) }
          let csc = CommonSuffixChoice(expansion: exp, preferredEndings: ends, preferredRegexes: regs)
          if let i = rs.index(where: { $0.abbreviation == abbr }) {
            rs[i].choices.append(csc)
          } else {
            rs.append(CommonSuffixRule(abbreviation: abbr, choices: [csc]))
          }
        }
      }
      _defaultRules = rs
      return rs
    }
    set {
      _defaultRules = newValue
      // save to user defaults
      let items: [[String]] = newValue.flatMap { r in
        r.choices.map { csc in
          var item = [r.abbreviation, csc.expansion]
          item.append(contentsOf: csc.preferredEndings)
          return item
        }
      }
      UserDefaults.standard.set(items, forKey: DefaultSuffixesKey)
    }
  }
  private static var _defaultRules: [CommonSuffixRule]? = nil
  
  public static func suggestCommonSuffixesFor(_ abbrev: AbbrevBase) -> [AbbrevBase] {
    let exp = abbrev.expansion
    let findSuggestions: (CommonSuffixRule) -> [AbbrevBase] = { csr in
      var cscs: [CommonSuffixChoice]
      if let csc = csr.choices.first(where: { $0.matches(exp) }) {
        cscs = [csc]
      }
      else {
        cscs = csr.choices.filter { $0.preferredEndings.count == 0 }
      }
      let abbs: [AbbrevBase] = cscs.map { csc in AbbrevBase(abbreviation: csr.abbreviation, expansion: csc.expansion) }
      return abbs
    }
    return CommonSuffixes.defaultRules.flatMap(findSuggestions)
  }
}

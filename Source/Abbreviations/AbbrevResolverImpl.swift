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

import Foundation


@objc(AbbrevResolverImpl)
public class AbbrevResolverImpl: NSObject, AbbrevResolver {
  private var index = [AnyHashable: Any]()
  private var duplicates = [AnyHashable: Any]()
  private var providers = [AbbrevListProvider]()
  
  public func addProvider(_ provider: AbbrevListProvider) {
    providers.append(provider)
    refresh()
  }
  
//  func addedDocument(_ document: AbbrevListDocument) {
//    documents.append(document)
//    NotificationCenter.default.addObserver(self,
//                                           selector: #selector(AbbrevResolverImpl.refresh),
//                                           name: NSNotification.Name(rawValue: AbbrevListDocumentModified),
//                                           object: document)
//    refresh()
//  }
  
  public func refresh() {
    var items = [AbbrevEntry]()
    for p in providers {
      items.append(contentsOf: p.getAbbreviations())
    }
    self.setItems(items)
  }
  
  func setItems(_ newItems: [AbbrevEntry]) {
    var newIndex = [String: Any](minimumCapacity: newItems.count)
    for a: AbbrevEntry in newItems {
      addToIndex(index: &newIndex, value: a, forKey: a.abbreviation)
      if let vs = a.variants {
        for v: AbbrevBase in vs {
          addToIndex(index: &newIndex, value: a, forKey: a.variantAbbreviation(v))
        }
      }
    }
    index = newIndex
  }
  
  func addToIndex(index: inout [String: Any], value: AbbrevEntry, forKey key: String) {
    if key == "" || value.expansion == "" {
      return
    }
    let k: String = key.lowercased()
    let existing = index[k]
    if let xv = existing {
      if var xvs = xv as? [AbbrevEntry] {
        xvs.append(value)
      }
      else if let xve = xv as? AbbrevEntry {
        index[k] = [xve, value]
      }
    }
    else {
      index[k] = value
    }
  }
  
  //
  // protocol AbbrevResolver
  //
  
  public func getExpansion(_ abbrev: String) -> String? {
    let key: String = abbrev.lowercased()
    let found: Any? = index[abbrev.lowercased()]
    if let v = found {
      if let a = v as? AbbrevEntry {
        if a.abbreviation.caseInsensitiveCompare(key) == .orderedSame {
          return a.expansion
        }
        else {
          if let vs = a.variants {
            for v in vs {
              if a.variantAbbreviation(v).caseInsensitiveCompare(key) == .orderedSame {
                return a.variantExpansion(v)
              }
            }
          }
        }
      }
    }
    return nil
  }

  public func hasDuplicateAbbreviation(_ a: AbbrevEntry) -> Bool {
    if isDuplicate(a.abbreviation) {
      return true
    }
    if let vs = a.variants {
      for v in vs {
        if isDuplicate(a.variantAbbreviation(v)) {
          return true
        }
      }
    }
    return false
  }

  func isDuplicate(_ abbrev: String) -> Bool {
    if let v = index[abbrev.lowercased()] {
      if let _ = v as? [AbbrevEntry] {
        return true
      }
    }
    return false
  }
}

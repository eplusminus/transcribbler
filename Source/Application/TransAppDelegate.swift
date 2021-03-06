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

import AbbreviationsEditor

import Cocoa
import Foundation

@NSApplicationMain
@objc(TransAppDelegate)
public class TransAppDelegate: NSResponder, NSApplicationDelegate {

  @IBOutlet private(set) var abbrevsController: AbbrevsController!
  
  public func applicationDidFinishLaunching(_ notification: Notification) {
    registerDefaults()
    AppPreferences.sharedInstance.loadPreferences()
  }
  
  @IBAction public func newAbbreviation(_ sender: AnyObject?) {
    abbrevsController.newAbbreviation(sender)
  }
  
  override public func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
    return abbrevsController.validateMenuItem(menuItem)
  }
  
  private func registerDefaults() {
    //UserDefaults.standard.removeObject(forKey: "CommonSuffixes")
    if let path = Bundle.main.path(forResource: "Defaults", ofType: "plist") {
      if let dict = NSDictionary(contentsOfFile: path) as? [String: Any] {
        UserDefaults.standard.register(defaults: dict)
      }
    }
  }
}

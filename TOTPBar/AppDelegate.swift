//
//  AppDelegate.swift
//  TOTPBar
//
//  Created by StanZhai on 2017/2/25.
//  Copyright © 2017年 StanZhai. All rights reserved.
//

import Cocoa
import Carbon
import Swifter

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    let keyboardMonitor = KeyboardMonitor()
    let mainWindowController = MainWindowController()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        keyboardMonitor.start()
        mainWindowController.showWindow(nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        keyboardMonitor.stop()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        mainWindowController.showWindow(nil)
        return true
    }
}

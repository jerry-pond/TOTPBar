//
//  StatusMenuController.swift
//  TOTPBar
//
//  Created by StanZhai on 2017/2/25.
//  Copyright © 2017年 StanZhai. All rights reserved.
//

import Cocoa
import Swifter

class StatusMenuController: NSObject {
    @IBOutlet weak var statusMenu: NSMenu!
    
    var statusItem: NSStatusItem!
    var timerMenuItem: NSMenuItem!
    var openMainWindowMenuItem: NSMenuItem!
    var httpServerSwitchMenuItem: NSMenuItem!
    var httpUrlMenuItem: NSMenuItem!
    var helpMenuItem: NSMenuItem!
    var quitMenuItem: NSMenuItem!
    var authCodeMenuItems: [NSMenuItem] = []

    var statusIcon: NSImage!
    var copyIcon: NSImage!

    var needRefreshCodeMenus: Bool = true
    let authCodeMenuItemTagStartIndex = 100
    var http: HttpServer!

    override func awakeFromNib() {
        loadIcons()
        initStatusItem()
        initStatusMenuItems()

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self,
                selector: #selector(verifyCodeAdded),
                name: NSNotification.Name(rawValue: "VerifyKeyAdded"),
                object: nil)
        notificationCenter.addObserver(self,
                selector: #selector(httpServerPortChanged),
                name: NSNotification.Name(rawValue: "HTTPServerPortChanged"),
                object: nil)
        notificationCenter.addObserver(self,
                selector: #selector(languageChanged),
                name: LanguageManager.didChangeNotification,
                object: nil)

        checkAutoStartHttpServer()
    }

    private func loadIcons() {
        statusIcon = NSImage(named: "statusIcon")
        statusIcon.size = NSMakeSize(20, 20)
        statusIcon.isTemplate = true

        let iconSize = NSMakeSize(14, 14)
        copyIcon = NSImage(named: "copyIcon")
        copyIcon.size = iconSize
        copyIcon.isTemplate = true
    }

    private func initStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.image = statusIcon
        statusItem.target = self
        statusItem.action = #selector(openMenu)
    }

    private func initStatusMenuItems() {
        statusMenu.removeAllItems()

        helpMenuItem = NSMenuItem(title: L("menu.help"), action: #selector(aboutClicked(sender:)), keyEquivalent: "h")
        helpMenuItem.target = self

        quitMenuItem = NSMenuItem(title: L("menu.quit"), action: #selector(quitClicked(sender:)), keyEquivalent: "q")
        quitMenuItem.target = self

        httpUrlMenuItem = NSMenuItem(title: "URL", action: #selector(urlClicked), keyEquivalent: "")
        httpUrlMenuItem.target = self

        statusMenu.addItem(httpUrlMenuItem)
        statusMenu.addItem(NSMenuItem.separator())
        statusMenu.addItem(helpMenuItem)
        statusMenu.addItem(quitMenuItem)

        statusMenu.insertItem(NSMenuItem.separator(), at: 0)
        openMainWindowMenuItem = NSMenuItem(title: L("main.open_window"), action: #selector(openMainWindowClicked), keyEquivalent: "")
        openMainWindowMenuItem.target = self
        statusMenu.insertItem(openMainWindowMenuItem, at: 0)

        httpServerSwitchMenuItem = NSMenuItem(title: L("http.start"), action: #selector(switchHttpServerClicked), keyEquivalent: "")
        httpServerSwitchMenuItem.target = self
        statusMenu.insertItem(httpServerSwitchMenuItem, at: 1)

        timerMenuItem = NSMenuItem()
        statusMenu.insertItem(timerMenuItem, at: 0)
    }

    @objc func openMenu(_ sender: AnyObject?) {
        updateStaticMenuTitles()
        updateMenu()
        updateHttpSwitchMenuItem()
        updateHttpURLMenuItem()
        let runLoop = RunLoop.current
        let timer = Timer(timeInterval: TimeInterval(1), target: self, selector: #selector(updateMenu), userInfo: nil, repeats: true)
        runLoop.add(timer, forMode: RunLoop.Mode.eventTracking)
        statusItem.popUpMenu(statusMenu)
        timer.invalidate()
    }

    @objc func updateMenu() {
        let now = Date()
        let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        let dateComponents = calendar.dateComponents([.second], from: now)
        let second = 30 - dateComponents.second! % 30

        timerMenuItem.title = "\(EXPIRE_TIME_STR)\(second)s"

        let authCodes = DataManager.shared.allAuthCode()

        if needRefreshCodeMenus {
            authCodeMenuItems.removeAll()

            for menuItem in statusMenu.items {
                if menuItem.tag >= authCodeMenuItemTagStartIndex {
                    statusMenu.removeItem(menuItem)
                }
            }

            var idx = 0
            for codeInfo in authCodes {
                let authCodeMenuItem = NSMenuItem()
                authCodeMenuItem.title = "\(codeInfo.key): \(codeInfo.value)"
                authCodeMenuItem.target = self
                authCodeMenuItem.action = #selector(authCodeMenuItemClicked)
                authCodeMenuItem.tag = authCodeMenuItemTagStartIndex + idx
                updateAuthCodeMenuItemState(authCodeMenuItem)
                authCodeMenuItem.keyEquivalent = "\(idx)"
                authCodeMenuItem.keyEquivalentModifierMask = [.command, .shift]
                authCodeMenuItems.append(authCodeMenuItem)
                statusMenu.insertItem(authCodeMenuItem, at: idx)
                idx = idx + 1
            }
            needRefreshCodeMenus = false
        } else {
            var idx = 0
            for codeInfo in authCodes {
                authCodeMenuItems[idx].title = "\(codeInfo.key): \(codeInfo.value)"
                updateAuthCodeMenuItemState(authCodeMenuItems[idx])
                idx = idx + 1
            }
        }
    }

    private func updateAuthCodeMenuItemState(_ authCodeMenuItem: NSMenuItem) {
        authCodeMenuItem.toolTip = COPY_AUTH_CODE_STR
        authCodeMenuItem.image = copyIcon
    }

    @objc func authCodeMenuItemClicked(_ sender: NSMenuItem) {
        let authCodes = DataManager.shared.allAuthCode()
        let dataIdx = sender.tag - authCodeMenuItemTagStartIndex
        if dataIdx < authCodes.count {
            var idx = 0
            for codeInfo in authCodes {
                if idx == dataIdx {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(codeInfo.value, forType: .string)
                    break
                }
                idx = idx + 1
            }
        }
    }

    @objc func verifyCodeAdded() {
        needRefreshCodeMenus = true
    }

    @objc func httpServerPortChanged() {
        updateHttpURLMenuItem()
        if (http != nil && http.state == HttpServerIO.HttpServerIOState.running) {
            restartHttpServer()
        }
        updateHttpSwitchMenuItem()
    }

    @objc func languageChanged() {
        updateStaticMenuTitles()
        needRefreshCodeMenus = true
    }

    private func updateStaticMenuTitles() {
        timerMenuItem.title = EXPIRE_TIME_STR
        openMainWindowMenuItem.title = L("main.open_window")
        helpMenuItem.title = L("menu.help")
        quitMenuItem.title = L("menu.quit")
        updateHttpSwitchMenuItem()
        updateHttpURLMenuItem()
    }
    
    private func updateHttpSwitchMenuItem() {
        if (http == nil || http.state != HttpServerIO.HttpServerIOState.running) {
            httpServerSwitchMenuItem.title = L("http.start")
        } else {
            httpServerSwitchMenuItem.title = L("http.stop")
        }
    }

    private func updateHttpURLMenuItem() {
        let serverPort = DataManager.shared.getHttpServerPort()
        let url = LF("http.open_url", serverPort)
        httpUrlMenuItem.title = url
        if (http == nil) {
            httpUrlMenuItem.isHidden = true
        } else {
            if (http.state == HttpServerIO.HttpServerIOState.running) {
                httpUrlMenuItem.isHidden = false
            } else {
                httpUrlMenuItem.isHidden = true
            }
        }
    }

    private func checkAutoStartHttpServer() {
        if (DataManager.shared.getHttpServerAutoStart()) {
            restartHttpServer()
        }
        updateHttpSwitchMenuItem()
    }

    private func stopHttpServer() {
        if (http != nil && http.state == HttpServerIO.HttpServerIOState.running) {
            http.stop()
        }
    }

    private func startHttpServer() {
        let serverPort = DataManager.shared.getHttpServerPort()
        if http == nil {
            http = httpServer()
        }
        do {
            try http.start(UInt16(serverPort)!, forceIPv4: true)
        } catch {
            let alert = NSAlert()
            alert.messageText = LF("http.start_failed", "\(error)")
            alert.runModal()
        }
    }

    private func restartHttpServer() {
        stopHttpServer()
        startHttpServer()
    }

    @IBAction func switchHttpServerClicked(_ sender: Any) {
        if (http == nil || http.state != HttpServerIO.HttpServerIOState.running) {
            startHttpServer()
        } else {
            stopHttpServer()
        }
        updateHttpSwitchMenuItem()
        updateHttpURLMenuItem()
    }

    @IBAction func urlClicked(_ sender: NSMenuItem) {
        let serverPort = DataManager.shared.getHttpServerPort()
        if let url = URL(string: "http://localhost:\(serverPort)") {
            NSWorkspace.shared.open(url)
        }
    }

    @IBAction func openMainWindowClicked(_ sender: NSMenuItem) {
        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.mainWindowController.showWindow(nil)
        }
    }
    
    @IBAction func aboutClicked(sender: NSMenuItem) {
        if let url = URL(string: "https://github.com/jerry-pond/TOTPBar") {
            NSWorkspace.shared.open(url)
        }
    }

    @IBAction func quitClicked(sender: NSMenuItem) {
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self)
        NSApplication.shared.terminate(self)
    }
}

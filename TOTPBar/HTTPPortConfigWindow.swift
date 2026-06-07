//
//  HTTPPortConfigWindow.swift
//  TOTPBar
//
//  Created by StanZhai on 2017/3/4.
//  Copyright © 2017年 StanZhai. All rights reserved.
//

import Cocoa

class HTTPPortConfigWindow: NSWindowController {

    @IBOutlet weak var portTextField: NSTextField!
    
    override var windowNibName : String! {
        return "HTTPPortConfigWindow"
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()

        self.window?.center()
        self.window?.title = L("http.port.window.title")
        portTextField.stringValue = DataManager.shared.getHttpServerPort()
        localizeSubviews(in: self.window?.contentView)
    }
    
    @IBAction func okClicked(_ sender: NSButton) {
        let alert: NSAlert = NSAlert()
        alert.addButton(withTitle: L("common.ok"))
        alert.alertStyle = NSAlert.Style.informational
        
        let port = portTextField.integerValue
        if port > 0 && port < 65535 {
            self.window?.close()
            
            let dataManager = DataManager.shared
            if port != Int(dataManager.getHttpServerPort()) {
                dataManager.saveHttpServerPort(port: "\(portTextField.integerValue)")
                
                let notificationCenter = NotificationCenter.default
                notificationCenter.post(name: NSNotification.Name(rawValue: "HTTPServerPortChanged"), object: nil)
                
                alert.messageText = L("http.port.updated")
                alert.runModal()
            }
            return
        }
        
        alert.messageText = L("http.port.invalid")
        alert.runModal()
    }

    private func localizeSubviews(in view: NSView?) {
        guard let view = view else {
            return
        }

        for subview in view.subviews {
            if let button = subview as? NSButton, button.title == "确定" {
                button.title = L("common.ok")
            } else if let textField = subview as? NSTextField,
                      !textField.isEditable,
                      textField.stringValue == "HTTP Server Port:" {
                textField.stringValue = L("http.port.label")
            }

            localizeSubviews(in: subview)
        }
    }
}

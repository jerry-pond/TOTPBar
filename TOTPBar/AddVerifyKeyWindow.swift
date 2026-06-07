//
//  AddVerifyKeyController.swift
//  TOTPBar
//
//  Created by StanZhai on 2017/2/25.
//  Copyright © 2017年 StanZhai. All rights reserved.
//

import Cocoa
import CoreImage

class AddVerifyKeyWindow: NSWindowController, NSWindowDelegate {
    @IBOutlet weak var otpTextField: NSTextField!
    @IBOutlet weak var tagTextField: NSTextField!
    var isEditing: Bool = false
    var originalTag: String = ""
    
    override var windowNibName : String! {
        return "AddVerifyKeyWindow"
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        self.window?.isOpaque = false
        //self.window?.titlebarAppearsTransparent = true
        //self.window?.styleMask = [window!.styleMask, .fullSizeContentView]
        let color = NSColor(calibratedRed: 0.0, green: 0.0, blue: 0.0, alpha: 0.75)
        //self.window?.backgroundColor = color
        self.window?.isMovableByWindowBackground = true
        self.window?.center()
        otpTextField.target = self
        otpTextField.action = #selector(otpTextFieldChanged)
        localizeSubviews(in: self.window?.contentView)
    }
    
    func clearTextField() {
        otpTextField.stringValue = ""
        tagTextField.stringValue = ""
        isEditing = false
        originalTag = ""
    }
    
    @IBAction func selectPicClicked(_ sender: NSButton) {
        let openPanel = NSOpenPanel()
        openPanel.allowedFileTypes = NSImage.imageTypes
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = true
        
        let i = openPanel.runModal()
        if i == NSApplication.ModalResponse.cancel {
            return
        }
        
        let ciImage = CIImage(contentsOf: openPanel.url!)
        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyLow])
        let results = detector?.features(in: ciImage!)
        if (results?.count)! > 0 {
            let qrFeature = results?.last as! CIQRCodeFeature
            let data = qrFeature.messageString
            otpTextField.stringValue = data!.trimmingCharacters(in: .whitespacesAndNewlines)
            updateTagFromOTPAuthURLIfNeeded(force: true)
            
        }
    }

    @IBAction func okBtnClicked(_ sender: NSButton) {
        let url = otpTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        var tag = tagTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        otpTextField.stringValue = url
        if tag.isEmpty, let otpInfo = OTPAuthURLParser(url) {
            tag = otpInfo.displayName
            tagTextField.stringValue = tag
        }
        
        let alert: NSAlert = NSAlert()
        alert.addButton(withTitle: L("common.ok"))
        alert.alertStyle = NSAlert.Style.informational
        
        var isValid = false
        if let otpInfo = OTPAuthURLParser(url) {
            isValid = OTPAuthURL.base32Decode(otpInfo.secret) != nil
        }
        
        if isValid {
            if isEditing {
                DataManager.shared.updateOTPAuthURL(oldTag: originalTag, newTag: tag, newUrl: url)
            } else {
                DataManager.shared.addOTPAuthURL(tag: tag, url: url)
            }
            
            let notificationCenter = NotificationCenter.default
            notificationCenter.post(name: NSNotification.Name(rawValue: "VerifyKeyAdded"), object: nil)
            self.window?.close()
            
            alert.messageText = isEditing ? L("auth.edit.success") : L("auth.add.success")
        } else {
            alert.messageText = L("auth.invalid_url")
            alert.alertStyle = NSAlert.Style.warning
        }
        
        alert.runModal()
    }
    
    @IBAction func cancelBtnClicked(_ sender: NSButton) {
        self.window?.close()
    }

    @objc private func otpTextFieldChanged() {
        otpTextField.stringValue = otpTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        updateTagFromOTPAuthURLIfNeeded(force: false)
    }

    private func updateTagFromOTPAuthURLIfNeeded(force: Bool) {
        let url = otpTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let otpInfo = OTPAuthURLParser(url) else {
            return
        }

        if force || tagTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            tagTextField.stringValue = otpInfo.displayName
        }
    }

    private func localizeSubviews(in view: NSView?) {
        guard let view = view else {
            return
        }

        for subview in view.subviews {
            if let button = subview as? NSButton {
                switch button.title {
                case "从二维码中识别...":
                    button.title = L("add.scan_qr")
                case "添加":
                    button.title = L("menu.add")
                default:
                    break
                }
            } else if let textField = subview as? NSTextField {
                if !textField.isEditable {
                    switch textField.stringValue {
                    case "OTPAuth URL：":
                        textField.stringValue = L("add.otpauth_url")
                    case "标识：":
                        textField.stringValue = L("add.tag")
                    default:
                        break
                    }
                } else if textField.placeholderString == "可选：为此验证码添加特定标识，便于识别" {
                    textField.placeholderString = L("add.tag.placeholder")
                }
            }

            localizeSubviews(in: subview)
        }
    }
}

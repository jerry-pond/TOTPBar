//
//  OTPAuthURLParser.swift
//  TOTPBar
//
//  Created by StanZhai on 2017/2/26.
//  Copyright © 2017年 StanZhai. All rights reserved.
//

import Foundation

class OTPAuthURLParser {
    var protocal: String
    var user: String?
    var host: String
    var secret: String
    var issuer: String?
    var label: String
    var displayName: String
    
    init?(_ otpAuthURL: String) {
        // otpauth://totp/user@host?secret=DA82347xxx&issuer=xxx
        // otpauth://totp/host?secret=ABCDEFG
        let trimmedURL = otpAuthURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmedURL),
              let hostValue = url.host,
              let components = URLComponents(string: trimmedURL),
              let secretValue = components.queryItems?.first(where: { $0.name == "secret" })?.value,
              !secretValue.isEmpty else {
            return nil
        }

        protocal = hostValue
        secret = secretValue
        issuer = components.queryItems?.first(where: { $0.name == "issuer" })?.value?.removingPercentEncoding

        label = url.lastPathComponent.removingPercentEncoding ?? url.lastPathComponent
        if label.isEmpty {
            return nil
        }

        let issuerPrefix = issuer.map { "\($0):" }
        let normalizedLabel: String
        if let issuerPrefix = issuerPrefix, label.hasPrefix(issuerPrefix) {
            normalizedLabel = String(label.dropFirst(issuerPrefix.count))
        } else {
            normalizedLabel = label
        }

        let parts = normalizedLabel.components(separatedBy: "@")

        if (parts.count > 1) {
            user = parts.first
            host = parts.dropFirst().joined(separator: "@")
        } else {
            host = normalizedLabel
        }

        if let issuer = issuer, let user = user, !issuer.isEmpty, !user.isEmpty {
            displayName = "\(issuer) - \(user)"
        } else if let issuer = issuer, !issuer.isEmpty {
            displayName = issuer
        } else {
            displayName = normalizedLabel
        }
    }
}

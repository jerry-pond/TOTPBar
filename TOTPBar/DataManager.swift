//
//  DataManager.swift
//  TOTPBar
//
//  Created by StanZhai on 2017/2/26.
//  Copyright © 2017年 StanZhai. All rights reserved.
//

import Foundation

struct AuthEntry {
    let tag: String
    let url: String
}

final class DataManager {
    static let shared = DataManager()
    private let authDataFile = "gp.secrets"
    private let configFile = "config.plist"
    private let authOrderKey = "auth_order"

    private var authData: [String: String]
    private var config: [String: String]

    private init() {
        authData = [:]
        config = [:]
        authData = loadData(authDataFile)
        config = loadData(configFile)
    }

    func addOTPAuthURL(tag: String, url: String) {
        let tag = normalizedTag(tag)
        authData[tag] = normalizedURL(url)
        appendAuthOrderIfNeeded(tag)
        saveData(authDataFile, data: authData)
        saveConfigData()
    }

    func removeOTPAuthURL(tag: String) {
        authData.removeValue(forKey: tag)
        saveAuthOrder(getAuthOrder().filter { $0 != tag })
        saveData(authDataFile, data: authData)
    }

    func updateOTPAuthURL(oldTag: String, newTag: String, newUrl: String) {
        if authData[oldTag] != nil {
            let newTag = normalizedTag(newTag)
            authData.removeValue(forKey: oldTag)
            authData[newTag] = normalizedURL(newUrl)
            saveAuthOrder(getAuthOrder().map { $0 == oldTag ? newTag : $0 })
            saveData(authDataFile, data: authData)
        }
    }

    func getOTPAuthURL(for tag: String) -> String? {
        return authData[tag]
    }

    func allAuthEntries() -> [AuthEntry] {
        return resolvedAuthOrder().compactMap { tag in
            guard let url = authData[tag] else {
                return nil
            }
            return AuthEntry(tag: tag, url: url)
        }
    }

    func moveAuthEntry(from sourceIndex: Int, to targetIndex: Int) {
        var order = resolvedAuthOrder()
        guard sourceIndex >= 0,
              sourceIndex < order.count,
              targetIndex >= 0,
              targetIndex <= order.count else {
            return
        }

        let tag = order.remove(at: sourceIndex)
        let adjustedTargetIndex = sourceIndex < targetIndex ? targetIndex - 1 : targetIndex
        order.insert(tag, at: adjustedTargetIndex)
        saveAuthOrder(order)
    }

    func verificationCode(for tag: String) -> String? {
        guard let url = authData[tag] else {
            return nil
        }
        return verificationCode(forURL: url)
    }

    func verificationCode(forOTPAuthURL url: String) -> String? {
        return verificationCode(forURL: normalizedURL(url))
    }

    func isValidOTPAuthURL(_ url: String) -> Bool {
        guard let otpInfo = OTPAuthURLParser(normalizedURL(url)) else {
            return false
        }
        return OTPAuthURL.base32Decode(otpInfo.secret) != nil
    }

    private func verificationCode(forURL url: String) -> String? {
        guard let otpData = OTPAuthURLParser(url),
              let data = OTPAuthURL.base32Decode(otpData.secret),
              let gen = TOTPGenerator(secret: data,
                                      algorithm: TOTPGenerator.defaultAlgorithm(),
                                      digits: TOTPGenerator.defaultDigits(),
                                      period: TOTPGenerator.defaultPeriod()) else {
            return nil
        }

        return gen.generateOTP(for: Date())
    }

    func allAuthCode() -> [(key: String, value: String)] {
        var result: [(key: String, value: String)] = []
        for entry in allAuthEntries() {
            result.append((key: entry.tag, value: verificationCode(forURL: entry.url) ?? "<get code failed>"))
        }
        return result
    }

    func dataCount() -> Int {
        return authData.count
    }

    func getHttpServerAutoStart() -> Bool {
        let auto = getConfig("http_server_auto_start")
        if (auto == nil || auto == "true") {
            return true;
        } else {
            return false;
        }
    }

    func saveHttpServerAutoStart(auto: Bool) {
        saveConfig(key: "http_server_auto_start", value: "\(auto)")
    }

    func getHttpServerPort() -> String {
        return getConfig("http_server_port") ?? "\(DEFAULT_HTTP_PORT)"
    }

    func saveHttpServerPort(port: String) {
        saveConfig(key: "http_server_port", value: port)
    }

    func getConfig(_ key: String) -> String? {
        return config[key]
    }

    func saveConfig(key: String, value: String) {
        config[key] = value
        saveConfigData()
    }

    func importData(dist: URL) -> Int {
        let d = NSKeyedUnarchiver.unarchiveObject(withFile: dist.path)
        if d == nil {
            return 0
        }
        let data = d as! [String: String]
        var count = 0;
        for k in data {
            let tag = normalizedTag(k.key)
            if authData[tag] == nil {
                authData[tag] = normalizedURL(k.value)
                appendAuthOrderIfNeeded(tag)
                count = count + 1
            }
        }
        saveData(authDataFile, data: authData)
        saveConfigData()
        return count
    }

    func exportData(dist: URL) {
        let fileLocation = "\(dataFilePath)\(authDataFile)"
        let fileUrl = URL(fileURLWithPath: fileLocation)
        let manager = FileManager.default
        try? manager.copyItem(at: fileUrl, to: dist)
    }

    private func saveData(_ dataFile: String, data: [String: String]) {
        let fileLocation = "\(dataFilePath)\(dataFile)"
        let fileUrl = URL(fileURLWithPath: fileLocation)
        try? NSKeyedArchiver.archivedData(withRootObject: data).write(to: fileUrl)
    }

    private func loadData(_ dataFile: String) -> [String: String] {
        let fileLocation = "\(dataFilePath)\(dataFile)"
        let d = NSKeyedUnarchiver.unarchiveObject(withFile: fileLocation)
        if d != nil {
            return d as! [String: String]
        }
        return [:]
    }

    private func saveConfigData() {
        saveData(configFile, data: config)
    }

    private func getAuthOrder() -> [String] {
        return (config[authOrderKey] ?? "")
            .components(separatedBy: "\n")
            .filter { !$0.isEmpty }
    }

    private func saveAuthOrder(_ order: [String]) {
        let existingTags = Set(authData.keys)
        var seen = Set<String>()
        let normalizedOrder = order.filter { tag in
            guard existingTags.contains(tag), !seen.contains(tag) else {
                return false
            }
            seen.insert(tag)
            return true
        }
        config[authOrderKey] = normalizedOrder.joined(separator: "\n")
        saveConfigData()
    }

    private func appendAuthOrderIfNeeded(_ tag: String) {
        var order = getAuthOrder()
        if !order.contains(tag) {
            order.append(tag)
            config[authOrderKey] = order.joined(separator: "\n")
        }
    }

    private func resolvedAuthOrder() -> [String] {
        let savedOrder = getAuthOrder()
        let savedSet = Set(savedOrder)
        let missingTags = authData.keys
            .filter { !savedSet.contains($0) }
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        let resolvedOrder = savedOrder.filter { authData[$0] != nil } + missingTags
        if resolvedOrder != savedOrder {
            saveAuthOrder(resolvedOrder)
        }
        return resolvedOrder
    }

    private var dataFilePath: String {
        let fileManager = FileManager.default
        let applicationSupportPath = NSSearchPathForDirectoriesInDomains(
            Foundation.FileManager.SearchPathDirectory.applicationSupportDirectory,
            Foundation.FileManager.SearchPathDomainMask.userDomainMask,
            true).first!
        let path = "\(applicationSupportPath)/TOTPBar/"
        let legacyPath = "\(applicationSupportPath)/TOTPBar/"

        if !fileManager.fileExists(atPath: path), fileManager.fileExists(atPath: legacyPath) {
            try? fileManager.copyItem(atPath: legacyPath, toPath: path)
        }

        if !fileManager.fileExists(atPath: path) {
            do {
                try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error)
            }
        }

        return path
    }

    private func normalizedTag(_ tag: String) -> String {
        return tag.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func normalizedURL(_ url: String) -> String {
        return url.trimmingCharacters(in: .whitespacesAndNewlines)
    }

}

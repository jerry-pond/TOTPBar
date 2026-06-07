//
//  HttpServer.swift
//  TOTPBar
//
//  Created by StanZhai on 2017/3/4.
//  Copyright © 2017年 StanZhai. All rights reserved.
//

import Foundation
import Swifter

public func httpServer() -> HttpServer {
    let server = HttpServer()
    server.listenAddressIPv4 = "127.0.0.1"
    
    server["/"] = { _ in
        var items = ""
        for code in DataManager.shared.allAuthCode() {
            let escapedKey = htmlEscaped(code.key)
            let escapedValue = htmlEscaped(code.value)
            items += "<li><a href=\"/code/\(escapedKey)\">\(escapedKey) -> \(escapedValue)</a></li>"
        }

        let page = """
        <!doctype html>
        <html>
        <head>
            <meta charset="utf-8">
            <title>TOTPBar</title>
        </head>
        <body>
            <h3>Verification code list:</h3>
            <ul>
                \(items)
            </ul>
        </body>
        </html>
        """

        return .raw(200, "OK", ["Content-Type": "text/html; charset=utf-8"]) { writer in
            try writer.write(page.data(using: .utf8)!)
        }
    }

    server["/code/:key"] = { r in
        let key = r.params[":key"]
        let allCodes = DataManager.shared.allAuthCode()
        for authInfo in allCodes {
            if authInfo.key == key! {
                return .raw(200, "OK", ["Content-Type": "text/plain; charset=utf-8"]) { writer in
                    try writer.write(authInfo.value.data(using: .utf8)!)
                }
            }
        }
        return .raw(200, "OK", ["Content-Type": "text/plain; charset=utf-8"]) { writer in
            try writer.write("key does not exists!".data(using: .utf8)!)
        }
    }
    
    return server
}

private func htmlEscaped(_ value: String) -> String {
    return value
        .replacingOccurrences(of: "&", with: "&amp;")
        .replacingOccurrences(of: "\"", with: "&quot;")
        .replacingOccurrences(of: "'", with: "&#39;")
        .replacingOccurrences(of: "<", with: "&lt;")
        .replacingOccurrences(of: ">", with: "&gt;")
}

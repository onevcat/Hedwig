//
//  Constant.swift
//  Hedwig
//
//  Created by WANG WEI on 16/12/27.
//
//

import Foundation

let CRLF = "\r\n"

var isTesting: Bool {
    for arg in ProcessInfo.processInfo.arguments {
        return arg.hasSuffix("usr/bin/xctest") || arg.hasSuffix("Xcode/Agents/xctest")
    }
    return false
}

func log(_ message: @autoclosure () -> String) {
    print("[Hedwig] SMTP Log: \(message())")
}

func logInTest(_ message: @autoclosure () -> String) {
    if isTesting {
        log(message)
    }
}

func logInDebug(_ message: @autoclosure () -> String) {
    #if DEBUG
    log(message)
    #endif
}

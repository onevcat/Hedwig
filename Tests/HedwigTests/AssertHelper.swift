//
//  AssertHelper.swift
//  Hedwig
//
//  Created by WANG WEI on 16/12/27.
//
//

import XCTest

public func XCTAssertNoThrows<T>(_ expression: @autoclosure () throws -> T, _ message: @autoclosure () -> String = "") {
    do {
        _ = try expression()
    } catch {
        XCTFail(message())
    }
}

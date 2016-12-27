//
//  Constant.swift
//  Hedwig
//
//  Created by WANG WEI on 16/12/27.
//
//

import Foundation

typealias Port = UInt16

extension Port {
    static let regular: Port = 25
    static let ssl: Port = 465
    static let tls: Port = 587
}

//
//  RegularExpressionExtensions.swift
//  Hedwig
//
//  Created by WANG WEI on 16/12/28.
//
//

import Foundation

extension NSRegularExpression {
    func groups(in string: String) -> [String] {
        let matches = self.matches(in: string, options: [], range: NSRange(location: 0, length: string.utf16.count))
        guard matches.count == 1 else { return [] }

        let s = string as NSString
        var mid = [String]()
        for i in 1 ..< matches[0].numberOfRanges {
            mid.append(s.substring(with: matches[0].rangeAt(i)))
        }
        return mid
    }
}

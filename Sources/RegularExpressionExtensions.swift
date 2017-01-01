//
//  RegularExpressionExtensions.swift
//  Hedwig
//
//  Created by WANG WEI on 16/12/28.
//
//

import Foundation

#if os(Linux)
    typealias Regex = RegularExpression
#else
    typealias Regex = NSRegularExpression
#endif

extension Regex {
    func groups(in string: String) -> [String] {
        let matches = self.matches(in: string, options: [], range: NSRange(location: 0, length: string.utf16.count))
        guard matches.count == 1 else { return [] }

        let s = NSString(string: string)
        var mid = [String]()
        for i in 1 ..< matches[0].numberOfRanges {
            #if os(Linux)
            let range = matches[0].range(at: i)
            #else
            let range = matches[0].rangeAt(i)
            #endif
            if range.location != NSNotFound {
                mid.append(s.substring(with: range))
            }
        }
        return mid
    }
}

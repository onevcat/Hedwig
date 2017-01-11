//
//  RegularExpressionExtensions.swift
//  Hedwig
//
//  Created by WANG WEI on 16/12/28.
//
//  Copyright (c) 2017 Wei Wang <onev@onevcat.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

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

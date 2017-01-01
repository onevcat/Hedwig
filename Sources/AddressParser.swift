//
//  AddressParser.swift
//  Hedwig
//
//  Created by Wei Wang on 2016/12/31.
//
//

import Foundation

struct Address {
    let name: String
    let entry: Entry
}

extension Address: Equatable {
    static func ==(lhs: Address, rhs: Address) -> Bool {
        return lhs.name == rhs.name && lhs.entry == rhs.entry
    }
}

indirect enum Entry {
    case mail(String)
    case group([Address])
}

extension Entry: Equatable {
    static func ==(lhs: Entry, rhs: Entry) -> Bool {
        switch (lhs, rhs) {
        case (.mail(let address1), .mail(let address2)): return address1 == address2
        case (.group(let addresses1), .group(let addresses2)): return addresses1 == addresses2
        default: return false
        }
    }
}

struct AddressParser {
    
    enum Node {
        case op(String)
        case text(String)
    }
    
    private enum ParsingState: Int {
        case address
        case comment
        case group
        case text
    }

    static func parse(_ text: String) -> [Address] {

        var address = [Node]()
        var addresses = [[Node]]()
        
        let nodes = Tokenizer(text: text).tokenize()
        nodes.forEach { (node) in
            if case .op(let value) = node, value == "," || value == ";" {
                if !address.isEmpty {
                    addresses.append(address)
                }
                address = []
            } else {
                address.append(node)
            }
        }
        
        if !address.isEmpty {
            addresses.append(address)
        }
        
        return addresses.flatMap(parseAddress)
    }
    
    static func parseAddress(address: [Node]) -> Address? {
        
        var parsing: [ParsingState: [String]] = [
            .address: [],
            .comment: [],
            .group: [],
            .text: []
        ]
        
        func parsingIsEmpty(_ state: ParsingState) -> Bool {
            return parsing[state]!.isEmpty
        }
        
        var state: ParsingState = .text
        var isGroup = false
        
        for node in address {
            if case .op(let op) = node {
                switch op {
                case "<":
                    state = .address
                case "(":
                    state = .comment
                case ":":
                    state = .group
                    isGroup = true
                default:
                    state = .text
                }
            } else if case .text(var value) = node {
                if state == .address {
                    value = value.truncateUnexpectedLessThanOp()
                }
                parsing[state]!.append(value)
            }
        }
        
        // If there is no text but a comment, use comment for text instead.
        if parsingIsEmpty(.text) && !parsingIsEmpty(.comment) {
            parsing[.text] = parsing[.comment]
            parsing[.comment] = []
        }
        
        if isGroup {
            // http://tools.ietf.org/html/rfc2822#appendix-A.1.3
            let name = parsing[.text]!.joined(separator: " ")
            let group = parsingIsEmpty(.group) ? [] : parse(parsing[.group]!.joined(separator: ","))
            return Address(name: name, entry: .group(group))
        } else {
            // No address found but there is text. Try to find an address from text.
            if parsingIsEmpty(.address) && !parsingIsEmpty(.text) {
                for text in parsing[.text]!.reversed() {
                    if text.isEmail {
                        let found = parsing[.text]!.removeLastMatch(text)!
                        parsing[.address]!.append(found)
                        break
                    }
                }
            }
            
            // Did not find an address in text. Try again with a looser condition.
            if parsingIsEmpty(.address) {
                var textHolder = [String]()
                for text in parsing[.text]!.reversed() {
                    if parsingIsEmpty(.address) {
                        let result = text.replacingMatch(regex: .looserMailRegex, with: "")
                        textHolder.append(result.afterReplacing)
                        if let matched = result.matched {
                            parsing[.address] = [matched.trimmingCharacters(in: .whitespaces)]
                        }
                    } else {
                        textHolder.append(text)
                    }
                }
                parsing[.text] = textHolder.reversed()
            }
            
            // If there is still no text but a comment, use comment for text instead.
            if parsingIsEmpty(.text) && !parsingIsEmpty(.comment) {
                parsing[.text] = parsing[.comment]
                parsing[.comment] = []
            }
            
            if parsing[.address]!.count > 1 {
                let keepAddress = parsing[.address]!.removeFirst()
                parsing[.text]?.append(contentsOf: parsing[.address]!)
                parsing[.address] = [keepAddress]
            }
            
            let tempText = parsing[.text]!.joined(separator: " ").nilOnEmpty
            
            // Remove single/douch quote mark in addresses
            let tempAddress = parsing[.address]!.joined(separator: " ").trimmingQuote.nilOnEmpty
            
            if address.isEmpty && isGroup {
                return nil
            } else {
                
                var address = tempAddress ?? tempText ?? ""
                var name = tempText ?? tempAddress ?? ""
                if address == name {
                    if address.contains("@") {
                        name = ""
                    } else {
                        address = ""
                    }
                }
            
                return Address(name: name, entry: .mail(address))
            }
        }
    }
    
    class Tokenizer {
        
        let operators: [Character: Character?] =
            ["\"": "\"", "(": ")", "<": ">",
             ",": nil, ":": ";", ";": nil]
        
        let text: String
        var currentOp: Character?
        var expectingOp: Character?
        var escaped = false
        
        var currentNode: Node?
        var list = [Node]()
        
        init(text: String) {
            self.text = text
        }
        
        func tokenize() -> [Node] {
            text.characters.forEach(check)
            appendCurrentNode()
            
            return list.filter { (node) -> Bool in
                let value: String
                switch node {
                case .op(let op): value = op
                case .text(let text): value = text
                }
                return !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
        }
        
        func check(char: Character) {
            if (operators.keys.contains(char) || char == "\\") && escaped {
                escaped = false
            } else if char == expectingOp {
                appendCurrentNode()
                list.append(.op(String(char)))
                expectingOp = nil
                escaped = false
                return
            } else if expectingOp == nil && operators.keys.contains(char) {
                appendCurrentNode()
                list.append(.op(String(char)))
                expectingOp = operators[char]!
                escaped = false
                return
            }
            
            
            
            if !escaped && char == "\\" {
                escaped = true
                return
            }
            
            if currentNode == nil {
                currentNode = .text("")
            }
            
            if case .text(var currentText) = currentNode! {
                if escaped && char != "\\" {
                    currentText.append("\\")
                }
                currentText.append(char)
                currentNode = .text(currentText)
                escaped = false
            }
        }
        
        func appendCurrentNode() {
            if let currentNode = currentNode {
                switch currentNode {
                case .op(let value):
                    list.append(.op(value.trimmingCharacters(in: .whitespacesAndNewlines)))
                case .text(let value):
                    list.append(.text(value.trimmingCharacters(in: .whitespacesAndNewlines)))
                }
            }
            currentNode = nil
        }
    }
}

extension NSRegularExpression {
    static let lessThanOpRegex = try! NSRegularExpression(pattern: "^[^<]*<\\s*", options: [])
    static let emailRegex = try! NSRegularExpression(pattern: "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}", options: [])
    static let quoteRegex = try! NSRegularExpression(pattern: "^(\"|\'){1}.+@.+(\"|\'){1}$", options: [])
    static let looserMailRegex = try! NSRegularExpression(pattern: "\\s*\\b[^@\\s]+@[^\\s]+\\b\\s*", options: [])
}

extension String {
    
    func truncateUnexpectedLessThanOp() -> String {
        let range = NSMakeRange(0, utf16.count)
        return NSRegularExpression.lessThanOpRegex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "")
    }
    
    var isEmail: Bool {
        let range = NSMakeRange(0, utf16.count)
        return !NSRegularExpression.emailRegex.matches(in: self, options: [], range: range).isEmpty
    }
    
    var trimmingQuote: String {
        let range = NSMakeRange(0, utf16.count)
        let result = NSRegularExpression.quoteRegex.matches(in: self, options: [], range: range)
        
        if !result.isEmpty {
            let r = NSMakeRange(1, utf16.count - 2)
            return (self as NSString).substring(with: r)
        } else {
            return self
        }
    }
    
    func replacingMatch(regex: NSRegularExpression, with replace: String) -> (afterReplacing: String, matched: String?) {
        let range = NSMakeRange(0, utf16.count)
        let matches = regex.matches(in: self, options: [], range: range)
        
        guard let firstMatch = matches.first else {
            return (self, nil)
        }
        
        let matched = (self as NSString).substring(with: firstMatch.range)
        let afterReplacing = (self as NSString).replacingCharacters(in: firstMatch.range, with: replace)
        
        return (afterReplacing, matched)
    }
    
    var nilOnEmpty: String? {
        return isEmpty ? nil : self
    }
}

extension Array where Element: Equatable {
    mutating func removeLastMatch(_ item: Element) -> Element? {
        guard let index = Array(reversed()).index(of: item) else {
            return nil
        }
        return remove(at: count - 1 - index)
    }
}

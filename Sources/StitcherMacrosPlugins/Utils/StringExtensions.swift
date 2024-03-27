//
//  StringExtensions.swift
//
//
//  Created by Αθανάσιος Κεφαλάς on 24/3/24.
//

struct StringEnvelope: Hashable, Equatable, CaseIterable {
    public let start: Character
    public let end: Character
    
    public init(start: Character, end: Character) {
        self.start = start
        self.end = end
    }
    
    public static let braces = StringEnvelope(start: "{", end: "}")
    public static let brackets = StringEnvelope(start: "[", end: "]")
    public static let generics = StringEnvelope(start: "<", end: ">")
    public static let parenthesis = StringEnvelope(start: "(", end: ")")
    public static let singleQuotes = StringEnvelope(start: "'", end: "'")
    public static let doubleQuotes = StringEnvelope(start: "\"", end: "\"")
    
    public static var allCases: [StringEnvelope] = [
        .braces,
        .brackets,
        .generics,
        .parenthesis,
        .singleQuotes,
        .doubleQuotes
    ]
}

extension String {
    
    func addingPrefix(_ prefix: String, separator: String = "") -> String {
        return "\(prefix)\(separator)\(self)"
    }
    
    func addingPrefix<Prefix: CustomStringConvertible>(_ prefix: Prefix, separator: String = "") -> String {
        return "\(prefix.description)\(separator)\(self)"
    }
    
    func removingPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix),
              let range = self.range(of: prefix) else {
            return self
        }
        
        return self.replacingOccurrences(of: prefix, with: "", range: range)
    }
    
    func addingSuffix(_ suffix: String, separator: String = "") -> String {
        return "\(self)\(separator)\(suffix)"
    }
    
    func addingSuffix<Suffix: CustomStringConvertible>(_ suffix: Suffix, separator: String = "") -> String {
        return "\(self)\(separator)\(suffix.description)"
    }
    
    func removingSuffix(_ suffix: String) -> String {
        guard self.hasSuffix(suffix),
              let range = self.range(of: suffix, options: .backwards) else {
            return self
        }
        
        return self.replacingOccurrences(of: suffix, with: "", range: range)
    }
    
    func isPlaced(in envelope: StringEnvelope) -> Bool {
        return hasPrefix("\(envelope.start)") && hasSuffix("\(envelope.end)")
    }
    
    func componentPlaced(in envelope: StringEnvelope) -> String? {
        
        guard contains("\(envelope.start)"), contains("\(envelope.end)") else {
            return nil
        }
        
        guard let componentStart = firstIndex(where: { $0 == envelope.start }),
              let componentEnd = lastIndex(where: { $0 == envelope.end }),
              componentStart >= startIndex,
              componentEnd >= componentStart,
              componentEnd < endIndex else {
            return nil
        }
        
        return String(self[componentStart...componentEnd])
            .removingEnvelope(envelope)
    }
    
    func removingEnvelope(_ envelope: StringEnvelope) -> String {
        guard isPlaced(in: envelope) else {
            return self
        }
        
        return self
            .removingPrefix("\(envelope.start)")
            .removingSuffix("\(envelope.end)")
    }
    
    func split(
        separator: Character,
        whenNotPlacedIn envelope: StringEnvelope
    ) -> [String] {
        var indent = 0
        var separatorIndices = [Index]()
        
        for index in self.indices {
            let character = self[index]
            
            switch character {
            case envelope.start:
                indent += 1
            case envelope.end:
                indent -= 1
            case separator:
                guard indent == 0 else {
                    continue
                }
                
                separatorIndices.append(index)
            default:
                continue
            }
        }
        
        return self.split(at: separatorIndices)
    }
    
    func split<Envelopes: Sequence>(
        separator: Character,
        whenNotPlacedIn envelopes: Envelopes
    ) -> [String] where Envelopes.Element == StringEnvelope {
        var separatorIndices = [Index]()
        var indents: [StringEnvelope : Int] = [:]
        
        for index in self.indices {
            let character = self[index]
            
            for envelope in envelopes {
                let indent = indents[envelope] ?? 0
                
                switch character {
                case envelope.start:
                    indents[envelope] = indent + 1
                case envelope.end:
                    indents[envelope] = indent - 1
                default:
                    continue
                }
            }
            
            guard character == separator else {
                continue
            }
            
            guard indents.values.reduce(0, +) < 1 else {
                continue
            }
            
            separatorIndices.append(index)
        }
        
        return self.split(at: separatorIndices)
    }
    
    func split(at indices: [Index]) -> [String] {
        
        guard !indices.isEmpty else {
            return [self]
        }
        
        var fromIndex = startIndex
        var stringComponents = [String]()
        
        for index in indices {
            let toIndex = index
            
            let component = String(self[fromIndex..<toIndex])
            stringComponents.append(component)
            
            fromIndex = self.index(after: toIndex)
        }
        
        let toIndex = endIndex
        let component = String(self[fromIndex..<toIndex])
        stringComponents.append(component)
        
        return stringComponents
    }
    
    func parsingCaseName() -> String? {
        
        guard contains(".") else {
            return self
        }
        
        let caseName = self.split(separator: ".", whenNotPlacedIn: .parenthesis)
            .filter({ !$0.isEmpty })
            .last
        
        guard let caseName else {
            return nil
        }
        
        if caseName.contains("(") {
            let associatedValueComponents = caseName.split(separator: "(", maxSplits: 1)
            return String(associatedValueComponents[0])
        }
        
        return String(caseName)
    }
    
    func parsingAssociatedValue() -> String? {
        guard contains(".") else {
            return self
        }
        
        let caseName = self.split(separator: ".", whenNotPlacedIn: .parenthesis)
            .filter({ !$0.isEmpty })
            .last
        
        guard let caseName else {
            return nil
        }
        
        return caseName.componentPlaced(in: .parenthesis)
    }
}

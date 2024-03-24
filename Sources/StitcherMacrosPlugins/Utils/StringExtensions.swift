//
//  StringExtensions.swift
//
//
//  Created by Αθανάσιος Κεφαλάς on 24/3/24.
//

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
    
    func removeEnvelope(of envelope: String) -> String {
        
        guard hasPrefix(envelope) && hasSuffix(envelope) else {
            return self
        }
        
        return self.removingPrefix(envelope).removingSuffix(envelope)
    }
}

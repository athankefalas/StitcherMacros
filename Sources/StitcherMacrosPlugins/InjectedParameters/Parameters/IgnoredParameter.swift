//
//  IgnoredParameter.swift
//
//
//  Created by Αθανάσιος Κεφαλάς on 24/3/24.
//
import SwiftSyntax

struct IgnoredParameter: RawRepresentable, Hashable {
    let rawValue: String
    
    init(rawValue: String) {
        self.rawValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func matches(syntax: FunctionParameterSyntax) -> Bool {
        let firstName = IgnoredParameter(rawValue: syntax.trimmed.firstName.trimmed.text)
        let secondName = IgnoredParameter(rawValue: syntax.trimmed.secondName?.trimmed.text ?? "")
        return self == firstName || self == secondName
    }
}

extension Set where Element == IgnoredParameter {
    
    func contains(_ syntax: FunctionParameterSyntax) -> Bool {
        let firstName = IgnoredParameter(rawValue: syntax.trimmed.firstName.trimmed.text)
        let secondName = IgnoredParameter(rawValue: syntax.trimmed.secondName?.trimmed.text ?? "")
        
        if secondName.rawValue == "" {
            return contains(firstName)
        }
        
        return contains(firstName) || contains(secondName)
    }
}

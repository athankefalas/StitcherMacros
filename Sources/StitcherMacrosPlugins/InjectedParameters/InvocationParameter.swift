//
//  InvocationParameter.swift
//
//
//  Created by Αθανάσιος Κεφαλάς on 24/3/24.
//

import SwiftSyntax

enum InvocationParameter {
    case injected(FunctionParameterSyntax)
    case forwarded(FunctionParameterSyntax)
    
    var name: String? {
        let rawName: String
        
        switch self {
        case .injected(let parameter):
            rawName = parameter.firstName.trimmed.text
        case .forwarded(let parameter):
            rawName = parameter.firstName.trimmed.text
        }
        
        if rawName == "_" {
            return nil
        }
        
        return rawName
    }
    
    var injectionName: String? {
        switch self {
        case .injected(let parameter):
            let rawName = parameter.secondName?.trimmedDescription ?? parameter.firstName.trimmedDescription
            
            if rawName == "_" {
                return nil
            }
            
            return rawName.addingEnvelope(.doubleQuotes)
        case .forwarded:
            return nil
        }
    }
    
    var isForwarded: Bool {
        switch self {
        case .injected:
            return false
        case .forwarded:
            return true
        }
    }
    
    var forwardedValue: String? {
        switch self {
        case .injected:
            return nil
        case .forwarded(let parameter):
            return parameter.secondName?.trimmed.text ?? parameter.firstName.trimmed.text
        }
    }
    
    var wrappedValue: FunctionParameterSyntax {
        switch self {
        case .injected(let parameter):
            return parameter
        case .forwarded(let parameter):
            return parameter
        }
    }
    
    static func wraping(
        from parameterSyntax: FunctionParameterSyntax,
        ignoredArguments: Set<IgnoredParameter>
    ) -> Self {
        
        if ignoredArguments.contains(parameterSyntax) {
            return .forwarded(parameterSyntax)
        } else {
            return .injected(parameterSyntax)
        }
    }
}

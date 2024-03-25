//
//  InjectedArgumentsDiagnostic.swift
//
//
//  Created by Αθανάσιος Κεφαλάς on 24/3/24.
//

import Foundation

public struct InjectedParametersDiagnostic: Error {
    
    public enum DiagnosticCode {
        case unknown
        case unexpectedDeclarationKind
        case malformedArguments
        case unknownIgnoredParameter(String)
        case cannotInjectGenericParameter(String)
    }
    
    public let code: DiagnosticCode
    
    init(code: DiagnosticCode) {
        self.code = code
    }
}

// MARK: InjectedParametersDiagnostic + CustomStringConvertible

extension InjectedParametersDiagnostic: CustomStringConvertible {
    
    public var description: String {
        switch code {
        case .unknown:
            return "An unexpected error occured while expanding the macro. Please consider filing a bug report."
        case .unexpectedDeclarationKind:
            return "This macro can only be used on function or initializer declarations."
        case .malformedArguments:
            return "Malformed arguments."
        case .unknownIgnoredParameter(let name):
            return "Malformed arguments. Ignored parameter '\(name)' does not match a known parameter name."
        case .cannotInjectGenericParameter(let name):
            return "Malformed arguments. Cannot inject generic parameter '\(name)'. Explicitly ignore the parameter."
        }
    }
}

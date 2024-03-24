//
//  InjectedArgumentsDiagnostic+CustomStringConvertible.swift
//
//
//  Created by Αθανάσιος Κεφαλάς on 23/3/24.
//


extension InjectedArgumentsDiagnostic: CustomStringConvertible {
    
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
        }
    }
}

//
//  InjectedArgumentsMacroDiagnostic+CustomStringConvertible.swift
//
//
//  Created by Αθανάσιος Κεφαλάς on 23/3/24.
//


extension InjectedArgumentsMacro.Diagnostic: CustomStringConvertible {
    
    public var description: String {
        switch code {
        case .unknown:
            return "An unexpected error occured while expanding the macro. Please consider filing a bug report."
        case .unexpectedDeclarationKind:
            return "This macro can only be used on function or initializer declarations."
        case .malformedArguments:
            return "Malformed arguments."
        }
    }
}

//
//  PreferredInitializerDiagnostic.swift
//
//
//  Created by Αθανάσιος Κεφαλάς on 25/3/24.
//

import Foundation

public struct PreferredInitializerDiagnostic: Error {
    
    public enum DiagnosticCode {
        case unknown
        case unexpectedDeclarationKind
        case unsupportedGenericArgument
        case unsupportedAsynchronous
        case unsupportedFailable
        case unsupportedThrowing
    }
    
    public let code: DiagnosticCode
    
    init(code: DiagnosticCode) {
        self.code = code
    }
}

// MARK: PreferredInitializerDiagnostic + CustomStringConvertible

extension PreferredInitializerDiagnostic: CustomStringConvertible {
    
    public var description: String {
        switch code {
        case .unknown:
            return "An unexpected error occured while expanding the macro. Please consider filing a bug report."
        case .unexpectedDeclarationKind:
            return "This macro can only be used on initializer declarations."
        case .unsupportedGenericArgument:
            return "Generic arguments are not supported."
        case .unsupportedAsynchronous:
            return "Async initializers are not supported."
        case .unsupportedFailable:
            return "Failable initializers are not supported."
        case .unsupportedThrowing:
            return "Throwing initializers are not supported."
        }
    }
}

//
//  RegisterableDiagnostic.swift
//
//
//  Created by Αθανάσιος Κεφαλάς on 26/3/24.
//

import Foundation

public struct RegisterableDiagnostic: Error {
    
    public enum DiagnosticCode {
        case unknown
        case malformedArguments
        case malformedArgumentsUnrelatedLocatorTypes
        case missingPreferredInitializer
        case multiplePreferredInitializersFound
        
    }
    
    public let code: DiagnosticCode
    
    init(code: DiagnosticCode) {
        self.code = code
    }
}

// MARK: RegisterableDiagnostic + CustomStringConvertible

extension RegisterableDiagnostic: CustomStringConvertible {
    
    public var description: String {
        switch code {
        case .unknown:
            return "An unexpected error occured while expanding the macro. Please consider filing a bug report."
        case .malformedArguments:
            return "Malformed arguments."
        case .malformedArgumentsUnrelatedLocatorTypes:
            return "Malformed arguments. The types specified in the dependency locator are not related to the attached dependency type."
        case .missingPreferredInitializer:
            return "Failed to find a supported preferred initializer. Please consider using the '@PreferredInitializer' attribute on a synchronous, non-failable initializer that has no generic arguments."
        case .multiplePreferredInitializersFound:
            return "Multiple supported initializers found. Please consider using the '@PreferredInitializer' attribute on a supported initializer, to use it for initializing the dependency."
        }
    }
}

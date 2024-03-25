//
//  InjectedArgumentsDiagnostic.swift
//
//
//  Created by Αθανάσιος Κεφαλάς on 24/3/24.
//

import Foundation

public struct InjectedArgumentsDiagnostic: Error {
    
    public enum DiagnosticCode {
        case unknown
        case unexpectedDeclarationKind
        case malformedArguments
        case unknownIgnoredParameter(String)
    }
    
    public let code: DiagnosticCode
    
    init(code: DiagnosticCode) {
        self.code = code
    }
}

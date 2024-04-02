//
//  PreferredInitializerMacro.swift
//
//
//  Created by Αθανάσιος Κεφαλάς on 25/3/24.
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxBuilder
import SwiftCompilerPlugin

public struct PreferredInitializerMacro: PeerMacro {
    typealias Diagnostic = PreferredInitializerDiagnostic
    
    static func supports(initializer: InitializerDeclSyntax) -> Bool {
        
        if hasGenericArguments(declaration: initializer) {
            return false
        }
        
        if initializer.signature.effectSpecifiers?.asyncSpecifier != nil {
            return false
        }
        
        if initializer.signature.effectSpecifiers?.throwsSpecifier != nil {
            return false
        }
        
        if initializer.optionalMark != nil {
            return false
        }
        
        return true
    }
    
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        guard declaration.kind == .initializerDecl,
              let initializer = declaration.as(InitializerDeclSyntax.self)?.trimmed else {
            
            throw Diagnostic(code: .unexpectedDeclarationKind)
        }
        
        if hasGenericArguments(declaration: initializer) {
            throw Diagnostic(code: .unsupportedGenericArgument)
        }
        
        if initializer.signature.effectSpecifiers?.asyncSpecifier != nil {
            throw Diagnostic(code: .unsupportedAsynchronous)
        }
        
        if initializer.signature.effectSpecifiers?.throwsSpecifier != nil {
            throw Diagnostic(code: .unsupportedThrowing)
        }
        
        if initializer.optionalMark != nil {
            throw Diagnostic(code: .unsupportedFailable)
        }
        
        return []
    }
    
    private static func hasGenericArguments(
        declaration initializer: InitializerDeclSyntax
    ) -> Bool {
        
        if initializer.genericParameterClause != nil {
            return true
        }
        
        let parameterNames = initializer.signature
            .parameterClause
            .parameters
            .map({ $0.type.trimmedDescription })
        
        for parameterName in parameterNames {
            if parameterName.hasPrefix("some ") {
                return true
            }
        }
        
        return false
    }
}

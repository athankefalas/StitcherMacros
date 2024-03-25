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
    
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        guard declaration.kind == .initializerDecl,
              let initializer = declaration.as(InitializerDeclSyntax.self)?.trimmed else {
            
            throw Diagnostic(code: .unexpectedDeclarationKind)
        }
        
        if initializer.genericParameterClause != nil {
            throw Diagnostic(code: .unexpectedGenericArgument)
        }
        
        return []
    }
}

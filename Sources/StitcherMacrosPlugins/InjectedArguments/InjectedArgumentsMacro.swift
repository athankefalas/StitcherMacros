//
//  InjectedArgumentsMacro.swift
//
//
//  Created by Αθανάσιος Κεφαλάς on 23/3/24.
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxBuilder
import SwiftCompilerPlugin

public struct InjectedArgumentsMacro: PeerMacro {
    typealias Diagnostic = InjectedArgumentsDiagnostic
    
    private static let rawAttributeSyntax = "@InjectedArguments"
    
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        let configuration = try InjectedParametersConfiguration.parsing(syntax: node)
        
        switch declaration.kind {
        case .functionDecl:
            return try injectedArgumentsFunctionExpansion(
                of: node,
                providingPeersOf: declaration,
                in: context,
                configuration: configuration
            )
        case .initializerDecl:
            return try injectedArgumentsInitializerExpansion(
                of: node,
                providingPeersOf: declaration,
                in: context,
                configuration: configuration
            )
        default:
            throw Diagnostic(code: .unexpectedDeclarationKind)
        }
    }

    private static func injectedArgumentsFunctionExpansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext,
        configuration: InjectedParametersConfiguration
    ) throws -> [DeclSyntax] {
        
        guard let originalFunction = declaration.as(FunctionDeclSyntax.self)?.trimmed else {
            throw Diagnostic(code: .unknown)
        }
        
        if originalFunction.signature.parameterClause.parameters.isEmpty {
            return []
        }
        
        let isMutating = originalFunction.modifiers.contains(where: { $0.trimmedDescription == "mutating" })
        let needsTriviaEnvelope = originalFunction.attributes.count == 1 && !isMutating
        var attributes = originalFunction.attributes
            .removingMacroDirective(Self.rawAttributeSyntax)
            .addingDisfavoredOverload()
        
        if needsTriviaEnvelope {
            attributes.leadingTrivia = .newline
            attributes.trailingTrivia = .newline
        }
                
        let ignoredParameters = configuration.ignoredParameters
        let originalParameters = originalFunction.signature.parameterClause.parameters
        
        try ensure(
            configuration: configuration,
            matchesParameters: originalParameters
        )
        
        let synthesizedParameters = originalParameters.filter({ ignoredParameters.contains($0) })
        let invocationParameters = originalParameters.map({
            InvocationParameter.wrap(from: $0, ignoredArguments: ignoredParameters)
        })
        
        let parameterClause = FunctionParameterClauseSyntax(
            parameters: synthesizedParameters
        )
        
        let signature = FunctionSignatureSyntax(
            leadingTrivia: originalFunction.signature.leadingTrivia,
            originalFunction.signature.unexpectedBeforeParameterClause,
            parameterClause: parameterClause,
            originalFunction.signature.unexpectedBetweenParameterClauseAndEffectSpecifiers,
            effectSpecifiers: originalFunction.signature.effectSpecifiers,
            originalFunction.signature.unexpectedBetweenEffectSpecifiersAndReturnClause,
            returnClause: originalFunction.signature.returnClause,
            originalFunction.signature.unexpectedAfterReturnClause,
            trailingTrivia: originalFunction.signature.trailingTrivia
        )
        
        let invocation = FunctionInvocationSyntax(
            configuration: configuration,
            invokedFunctionDeclaration: originalFunction,
            invocationParameters: invocationParameters
        )
        
        let function = FunctionDeclSyntax(
            leadingTrivia: originalFunction.leadingTrivia,
            originalFunction.unexpectedBeforeAttributes,
            attributes: attributes,
            originalFunction.unexpectedBetweenAttributesAndModifiers,
            modifiers: originalFunction.modifiers,
            originalFunction.unexpectedBetweenModifiersAndFuncKeyword,
            funcKeyword: originalFunction.funcKeyword.trimmed,
            originalFunction.unexpectedBetweenFuncKeywordAndName,
            name: originalFunction.name,
            originalFunction.unexpectedBetweenNameAndGenericParameterClause,
            genericParameterClause: originalFunction.genericParameterClause,
            originalFunction.unexpectedBetweenGenericParameterClauseAndSignature,
            signature: signature,
            originalFunction.unexpectedBetweenSignatureAndGenericWhereClause,
            genericWhereClause: originalFunction.genericWhereClause,
            originalFunction.unexpectedBetweenGenericWhereClauseAndBody,
            body: invocation.blockWrappedSyntax(),
            originalFunction.unexpectedAfterBody,
            trailingTrivia: originalFunction.trailingTrivia
        )
        
        return [
            DeclSyntax(function)
        ]
    }
    
    private static func injectedArgumentsInitializerExpansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext,
        configuration: InjectedParametersConfiguration
    ) throws -> [DeclSyntax] {
        
        guard declaration.kind == .functionDecl || declaration.kind == .initializerDecl else {
            throw Diagnostic(code: .unexpectedDeclarationKind)
        }
        
        return []
    }
    
    private static func ensure(
        configuration: InjectedParametersConfiguration,
        matchesParameters parameters: FunctionParameterListSyntax
    ) throws {
        
        for ignoredParameter in configuration.ignoredParameters {
            
            guard !parameters.contains(where: { ignoredParameter.matches(syntax: $0) }) else {
                continue
            }
            
            throw InjectedArgumentsDiagnostic(code: .unknownIgnoredParameter(ignoredParameter.rawValue))
        }
    }
}

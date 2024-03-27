//
//  InjectedParametersMacro.swift
//
//
//  Created by Αθανάσιος Κεφαλάς on 23/3/24.
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxBuilder
import SwiftCompilerPlugin

public struct InjectedParametersMacro: PeerMacro {
    typealias Diagnostic = InjectedParametersDiagnostic
        
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
            .removingMacroDirective(.injectedParameters)
            .addingDisfavoredOverload()
        
        if needsTriviaEnvelope {
            attributes.leadingTrivia = .newline
            attributes.trailingTrivia = .newline
        }
                
        let ignoredParameters = configuration.ignoredParameters
        let originalParameters = originalFunction.signature.parameterClause.parameters
        
        try validate(
            configuration: configuration,
            matchesGenerics: originalFunction.genericParameterClause,
            andParameters: originalParameters
        )
        
        var synthesizedParameters = originalParameters.filter({ ignoredParameters.contains($0) })
        let invocationParameters = originalParameters.map({
            InvocationParameter.wraping(from: $0, ignoredArguments: ignoredParameters)
        })
        
        if synthesizedParameters.count > 0 {
            let lastIndex = synthesizedParameters.index(before: synthesizedParameters.endIndex)
            synthesizedParameters[lastIndex].trailingComma = nil
        }
        
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
        
        guard var originalInitializer = declaration.as(InitializerDeclSyntax.self)?.trimmed else {
            throw Diagnostic(code: .unknown)
        }
        
        if originalInitializer.signature.parameterClause.parameters.isEmpty {
            return []
        }
        
        let needsTriviaEnvelope = originalInitializer.attributes.count == 1
        var attributes = originalInitializer.attributes
            .removingMacroDirective(.injectedParameters)
            .addingDisfavoredOverload()
        
        if PreferredInitializerMacro.supports(initializer: originalInitializer) {
            attributes.addMacroDirective(.preferredInitializer)
        }
        
        if needsTriviaEnvelope {
            attributes.leadingTrivia = .newline
            attributes.trailingTrivia = .newline
        }
        
        var modifiers = originalInitializer.modifiers
        
        if originalInitializer.modifiers.isEmpty {
            modifiers.leadingTrivia = originalInitializer.initKeyword.leadingTrivia
            originalInitializer.initKeyword.leadingTrivia = configuration.parent.usesReferenceSemantics ? .space : .init(stringLiteral: "")
        }
        
        if configuration.parent.usesReferenceSemantics {
            modifiers.append(.init(name: .keyword(.convenience)))
        }
        
        let ignoredParameters = configuration.ignoredParameters
        let originalParameters = originalInitializer.signature.parameterClause.parameters
        
        try validate(
            configuration: configuration,
            matchesGenerics: originalInitializer.genericParameterClause,
            andParameters: originalParameters
        )
        
        var synthesizedParameters = originalParameters.filter({ ignoredParameters.contains($0) })
        let invocationParameters = originalParameters.map({
            InvocationParameter.wraping(from: $0, ignoredArguments: ignoredParameters)
        })
        
        if synthesizedParameters.count > 0 {
            let lastIndex = synthesizedParameters.index(before: synthesizedParameters.endIndex)
            synthesizedParameters[lastIndex].trailingComma = nil
        }
        
        let parameterClause = FunctionParameterClauseSyntax(
            parameters: synthesizedParameters
        )
        
        let signature = FunctionSignatureSyntax(
            leadingTrivia: originalInitializer.signature.leadingTrivia,
            originalInitializer.signature.unexpectedBeforeParameterClause,
            parameterClause: parameterClause,
            originalInitializer.signature.unexpectedBetweenParameterClauseAndEffectSpecifiers,
            effectSpecifiers: originalInitializer.signature.effectSpecifiers,
            originalInitializer.signature.unexpectedBetweenEffectSpecifiersAndReturnClause,
            returnClause: originalInitializer.signature.returnClause,
            originalInitializer.signature.unexpectedAfterReturnClause,
            trailingTrivia: originalInitializer.signature.trailingTrivia
        )
        
        let invocation = InitializerInvocationSyntax(
            configuration: configuration,
            invocationTarget: "self",
            invokedFunctionDeclaration: originalInitializer,
            invocationParameters: invocationParameters
        )
        
        let initializer = InitializerDeclSyntax(
            leadingTrivia: originalInitializer.leadingTrivia,
            originalInitializer.unexpectedBeforeAttributes,
            attributes: attributes,
            originalInitializer.unexpectedBetweenAttributesAndModifiers,
            modifiers: modifiers,
            originalInitializer.unexpectedBetweenModifiersAndInitKeyword,
            initKeyword: originalInitializer.initKeyword,
            originalInitializer.unexpectedBetweenInitKeywordAndOptionalMark,
            optionalMark: originalInitializer.optionalMark,
            originalInitializer.unexpectedBetweenOptionalMarkAndGenericParameterClause,
            genericParameterClause: originalInitializer.genericParameterClause,
            originalInitializer.unexpectedBetweenGenericParameterClauseAndSignature,
            signature: signature,
            originalInitializer.unexpectedBetweenSignatureAndGenericWhereClause,
            genericWhereClause: originalInitializer.genericWhereClause,
            originalInitializer.unexpectedBetweenGenericWhereClauseAndBody,
            body: invocation.blockWrappedSyntax(),
            originalInitializer.unexpectedAfterBody,
            trailingTrivia: originalInitializer.trailingTrivia
        )
        
        return [
            DeclSyntax(initializer)
        ]
    }
    
    // MARK: AST Validation
    
    private static func validate(
        configuration: InjectedParametersConfiguration,
        matchesGenerics generics: GenericParameterClauseSyntax?,
        andParameters parameters: FunctionParameterListSyntax
    ) throws {
        try ensure(configuration: configuration, matchesParameters: parameters)
        try ensure(configuration: configuration, matchesGenerics: generics, andParameters: parameters)
    }
    
    private static func ensure(
        configuration: InjectedParametersConfiguration,
        matchesParameters parameters: FunctionParameterListSyntax
    ) throws {
        
        for ignoredParameter in configuration.ignoredParameters {
            
            guard !parameters.contains(where: { ignoredParameter.matches(syntax: $0) }) else {
                continue
            }
            
            throw InjectedParametersDiagnostic(code: .unknownIgnoredParameter(ignoredParameter.rawValue))
        }
    }
    
    private static func ensure(
        configuration: InjectedParametersConfiguration,
        matchesGenerics generics: GenericParameterClauseSyntax?,
        andParameters parameters: FunctionParameterListSyntax
    ) throws {
        
        guard let generics else {
            return
        }
        
        let genericTypes = Set(generics.parameters.map({ $0.trimmed.name.description }))
        
        for parameter in parameters {
            let parameterName = parameter.secondName?.trimmedDescription ?? parameter.firstName.trimmedDescription
            let parameterType = parameter.type.trimmedDescription
            
            guard genericTypes.contains(parameterType) && !configuration.ignoredParameters.contains(parameter) else {
                continue
            }
            
            throw InjectedParametersDiagnostic(code: .cannotInjectGenericParameter(parameterName))
        }
    }
}

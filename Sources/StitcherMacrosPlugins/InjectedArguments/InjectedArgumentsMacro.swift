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
    
    public enum DiagnosticCode {
        case unknown
        case unexpectedDeclarationKind
        case malformedArguments
    }
    
    public struct Diagnostic: Error {
        
        public let code: DiagnosticCode
        
        init(code: DiagnosticCode) {
            self.code = code
        }
    }
    
    private struct LogDiagnostic: Error, CustomStringConvertible {
        
        let message: String
        
        var description: String {
            message
        }
        
        init(_ message: String) {
            self.message = message
        }
        
    }
    
    
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        let parameterParser = InjectedParametersConfiguration.Parser()
        let parameters = try parameterParser.parse(syntax: node)
        
        switch declaration.kind {
        case .functionDecl:
            return try injectedArgumentsFunctionExpansion(
                of: node,
                providingPeersOf: declaration,
                in: context,
                parameters: parameters
            )
        case .initializerDecl:
            return try injectedArgumentsInitializerExpansion(
                of: node,
                providingPeersOf: declaration,
                in: context,
                parameters: parameters
            )
        default:
            throw Diagnostic(code: .unexpectedDeclarationKind)
        }
    }

    private static func injectedArgumentsFunctionExpansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext,
        parameters: InjectedParametersConfiguration
    ) throws -> [DeclSyntax] {
        
        guard let originalFunction = declaration.as(FunctionDeclSyntax.self)?.trimmed else {
            throw Diagnostic(code: .unknown)
        }
        
        if originalFunction.signature.parameterClause.parameters.isEmpty {
            return []
        }
        
        var attributes = originalFunction.attributes.filter({ !$0.trimmed.description.contains("@InjectedArguments") })
        
        if !attributes.contains(where: { $0.trimmed.description == "@_disfavoredOverload" }) {
            attributes.append(.attribute("@disfavoredOverload"))
        }
        
        let ignoredParameters = parameters.ignoredParameters
        let originalParameters = originalFunction.signature.parameterClause.parameters
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
        
        let invocation = callFunctionSyntax(
            calling: originalFunction,
            parameters: invocationParameters,
            codeGenerator: parameters.generator
        )
        
        var statements = CodeBlockItemListSyntax()
        statements.append(
            CodeBlockItemSyntax(item: CodeBlockItemSyntax.Item(invocation))
        )
        
        let function = FunctionDeclSyntax(
            leadingTrivia: originalFunction.leadingTrivia,
            originalFunction.unexpectedBeforeAttributes,
            attributes: attributes,
            originalFunction.unexpectedBetweenAttributesAndModifiers,
            modifiers: originalFunction.modifiers,
            originalFunction.unexpectedBetweenModifiersAndFuncKeyword,
            funcKeyword: originalFunction.funcKeyword,
            originalFunction.unexpectedBetweenFuncKeywordAndName,
            name: originalFunction.name,
            originalFunction.unexpectedBetweenNameAndGenericParameterClause,
            genericParameterClause: originalFunction.genericParameterClause,
            originalFunction.unexpectedBetweenGenericParameterClauseAndSignature,
            signature: signature,
            originalFunction.unexpectedBetweenSignatureAndGenericWhereClause,
            genericWhereClause: originalFunction.genericWhereClause,
            originalFunction.unexpectedBetweenGenericWhereClauseAndBody,
            body: CodeBlockSyntax(statements: statements),
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
        parameters: InjectedParametersConfiguration
    ) throws -> [DeclSyntax] {
        
        guard declaration.kind == .functionDecl || declaration.kind == .initializerDecl else {
            throw Diagnostic(code: .unexpectedDeclarationKind)
        }
        
        return []
    }
}

func callFunctionSyntax(
    calling function: FunctionDeclSyntax,
    from callee: String? = nil,
    parameters: [InvocationParameter],
    codeGenerator: InjectionCodeGenerator
) -> FunctionCallExprSyntax {
    
    let invocation = invocationSyntax(calling: function, from: callee)
    var argumentList = LabeledExprListSyntax()
    
    for parameterIndexPair in parameters.enumerated() {
        let parameter = parameterIndexPair.element
        let isLastParameter = parameterIndexPair.offset < parameters.count - 1
        var labeledExpression = LabeledExprSyntax(
            label: parameter.name,
            expression: parameterValueSyntax(
                of: parameter,
                generator: codeGenerator
            )
        )
                
        if isLastParameter {
            labeledExpression.trailingComma = .commaToken()
        }
        
        argumentList.append(labeledExpression)
    }
    
    return FunctionCallExprSyntax(
        leadingTrivia: nil,
        calledExpression: invocation,
        leftParen: .leftParenToken(),
        arguments: argumentList,
        rightParen: .rightParenToken(),
        trailingTrivia: nil
    )
}

func invocationSyntax(
    calling function: FunctionDeclSyntax,
    from callee: String?
) -> ExprSyntax {
    
    let functionName = function.name.trimmed.text
    let invocationExpression = invocationEffectSyntaxPrefix(for: function) + functionName
    
    guard let callee = callee, callee.count > 0 else {
        return ExprSyntax(stringLiteral: invocationExpression)
    }
    
    return ExprSyntax(stringLiteral: "\(callee).\(invocationExpression)")
}

func invocationEffectSyntaxPrefix(
    for function: FunctionDeclSyntax
) -> String {
    
    var prefix = ""
    
    if function.signature.effectSpecifiers?.throwsSpecifier != nil {
        prefix += "try "
    }
    
    if function.signature.effectSpecifiers?.asyncSpecifier != nil {
        prefix += "await "
    }
    
    return prefix
}

func parameterValueSyntax(
    of parameter: InvocationParameter,
    generator: InjectionCodeGenerator
) -> ExprSyntax {
    
    if let forwardedValue = parameter.forwardedValue {
        return ExprSyntax(stringLiteral: forwardedValue)
    }
    
    let generatedCode = generator.generateInjectionExpression(
        parameterName: parameter.name,
        parameterTypeName: parameter.wrappedValue.type.trimmed.description
    )
    
    return ExprSyntax(stringLiteral: generatedCode)
}

//
//  InitializerInvocationSyntax.swift
//
//
//  Created by Αθανάσιος Κεφαλάς on 25/3/24.
//

import SwiftSyntax

struct InitializerInvocationSyntax {
    
    let configuration: InjectedParametersConfiguration
    let invocationTarget: String?
    let invokedFunctionDeclaration: InitializerDeclSyntax
    let invocationParameters: [InvocationParameter]
    
    init(
        configuration: InjectedParametersConfiguration,
        invocationTarget: String? = nil,
        invokedFunctionDeclaration: InitializerDeclSyntax,
        invocationParameters: [InvocationParameter] = []
    ) {
        self.configuration = configuration
        self.invocationTarget = invocationTarget
        self.invokedFunctionDeclaration = invokedFunctionDeclaration
        self.invocationParameters = invocationParameters
    }
    
    func syntax() -> FunctionCallExprSyntax {
        let invocation = invocationSyntax()
        var argumentList = LabeledExprListSyntax()
        
        for parameterIndexPair in invocationParameters.enumerated() {
            let parameter = parameterIndexPair.element
            let isLastParameter = parameterIndexPair.offset < invocationParameters.count - 1
            var labeledExpression = LabeledExprSyntax(
                label: parameter.name,
                expression: parameterValueSyntax(
                    of: parameter
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
    
    func blockWrappedSyntax(leadingTrivia: Trivia? = nil, trailingTrivia: Trivia? = nil) -> CodeBlockSyntax {
        let invocation = syntax()
        var statements = CodeBlockItemListSyntax()
        
        if let leadingTrivia {
            statements.leadingTrivia = leadingTrivia
        }
        
        if let trailingTrivia {
            statements.trailingTrivia = trailingTrivia
        }
        
        statements.append(
            CodeBlockItemSyntax(item: CodeBlockItemSyntax.Item(invocation))
        )
        
        return CodeBlockSyntax(
            leadingTrivia: nil,
            statements: statements,
            trailingTrivia: nil
        )
    }
    
    private func invocationSyntax() -> ExprSyntax {
        
        let functionName = "init"
        let invocationExpression = invocationEffectSyntaxPrefix() + functionName
        
        guard let invocationTarget = invocationTarget, invocationTarget.count > 0 else {
            return ExprSyntax(stringLiteral: invocationExpression)
        }
        
        return ExprSyntax(stringLiteral: "\(invocationTarget).\(invocationExpression)")
    }

    private func invocationEffectSyntaxPrefix() -> String {
        
        var prefix = ""
        
        if invokedFunctionDeclaration.signature.effectSpecifiers?.throwsSpecifier != nil {
            prefix += "try "
        }
        
        if invokedFunctionDeclaration.signature.effectSpecifiers?.asyncSpecifier != nil {
            prefix += "await "
        }
        
        return prefix
    }

    private func parameterValueSyntax(
        of parameter: InvocationParameter
    ) -> ExprSyntax {
        
        if let forwardedValue = parameter.forwardedValue {
            return ExprSyntax(stringLiteral: forwardedValue)
        }
        
        var parameterTypeName = parameter.wrappedValue.type.trimmed.description
        
        if parameterTypeName.hasPrefix("any ") {
            parameterTypeName = parameterTypeName.addingEnvelope(.parenthesis)
        }
        
        let generatedCode = configuration.generator.generateInjectionExpression(
            parameterName: parameter.injectionName,
            parameterTypeName: parameterTypeName
        )
        
        return ExprSyntax(stringLiteral: generatedCode)
    }
}

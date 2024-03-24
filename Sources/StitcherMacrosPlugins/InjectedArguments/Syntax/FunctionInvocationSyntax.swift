//
//  FunctionInvocationSyntax.swift
//
//
//  Created by Αθανάσιος Κεφαλάς on 24/3/24.
//

import SwiftSyntax

struct FunctionInvocationSyntax {
    
    let configuration: InjectedParametersConfiguration
    let invocationTarget: String?
    let invokedFunctionDeclaration: FunctionDeclSyntax
    let invocationParameters: [InvocationParameter]
    
    init(
        configuration: InjectedParametersConfiguration,
        invocationTarget: String? = nil,
        invokedFunctionDeclaration: FunctionDeclSyntax,
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
    
    func blockWrappedSyntax() -> CodeBlockSyntax {
        let invocation = syntax()
        var statements = CodeBlockItemListSyntax()
        statements.append(
            CodeBlockItemSyntax(item: CodeBlockItemSyntax.Item(invocation))
        )
        
        return CodeBlockSyntax(statements: statements)
    }
    
    private func invocationSyntax() -> ExprSyntax {
        
        let functionName = invokedFunctionDeclaration.name.trimmed.text
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
        
        let generatedCode = configuration.generator.generateInjectionExpression(
            parameterName: parameter.name,
            parameterTypeName: parameter.wrappedValue.type.trimmed.description
        )
        
        return ExprSyntax(stringLiteral: generatedCode)
    }
}

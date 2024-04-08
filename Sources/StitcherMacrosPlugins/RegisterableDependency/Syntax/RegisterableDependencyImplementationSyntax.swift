//
//  RegisterableDependencyImplementationSyntax.swift
//
//
//  Created by Αθανάσιος Κεφαλάς on 26/3/24.
//

import Stitcher
import SwiftSyntax
import SwiftSyntaxBuilder

struct RegisterableDependencyImplementationSyntax<T: TypeSyntaxProtocol, Definition: DeclGroupSyntax> {
    
    private let generator: AutoregisterableDependencyCodeGenerator
    private let configuration: RegisterableConfiguration
    private let typeDeclaration: T
    private let typeDefinition: Definition
    private let preferredInitializer: InitializerDeclSyntax
    
    init(
        configuration: RegisterableConfiguration,
        type: T,
        definition: Definition,
        preferredInitializer: InitializerDeclSyntax
    ) {
        self.generator = AutoregisterableDependencyCodeGenerator()
        self.configuration = configuration
        self.typeDeclaration = type
        self.typeDefinition = definition
        self.preferredInitializer = preferredInitializer
    }
    
    func syntax() -> MemberBlockSyntax {
        var members = MemberBlockItemListSyntax()
        
        if configuration.locator?.kind == .name || configuration.locator?.kind == .value {
            members.append(dependencyLocatorValueMemberSyntax())
        }
        
        members.append(dependencyRegistrationMemberSyntax())
        return MemberBlockSyntax(members: members)
    }
    
    private func dependencyLocatorValueMemberSyntax() -> MemberBlockItemSyntax {
        let propertyValue = configuration.locator ?? .locator(forType: typeDeclaration)
        let rawPropertyValue: String
        
        switch propertyValue.kind {
        case .name:
            rawPropertyValue = propertyValue.rawValue.parsingAssociatedValue() ?? propertyValue.rawValue
        case .value:
            rawPropertyValue = propertyValue.rawValue.parsingAssociatedValue() ?? propertyValue.rawValue
        default:
            rawPropertyValue = propertyValue.rawValue
        }
        
        let propertyDeclaration = PropertyDeclarationSyntax(
            attachment: .type,
            mutability: .constant,
            accessModifier: .fromType(typeDeclaration: typeDefinition),
            propertyType: configuration.locator?.kind == .name ? "String" : "AnyHashable",
            propertyName: configuration.locator?.kind == .name ? "dependencyName" : "dependencyValue",
            propertyValue: InitializerClauseSyntax(
                value: ExprSyntax(stringLiteral: rawPropertyValue)
            )
        )
        
        return propertyDeclaration.memberWrappedSyntax(leadingTrivia: .newline)
    }
    
    private func dependencyRegistrationMemberSyntax() -> MemberBlockItemSyntax {
        let propertyDeclaration = PropertyDeclarationSyntax(
            attachment: .type,
            mutability: .constant,
            accessModifier: .fromType(typeDeclaration: typeDefinition),
            propertyType: nil,
            propertyName: generator.autoregistrationContainerPropertyName(),
            propertyValue: InitializerClauseSyntax(
                value: generatedDependencyInitializerExpression()
            )
        )
        
        return propertyDeclaration.memberWrappedSyntax(leadingTrivia: .newline)
    }
    
    private func generatedDependencyInitializerExpression() -> ExprSyntaxProtocol {
        let type = generator.generateAutoregistrationContainerExpression(
            typeName: typeDeclaration.trimmedDescription
        )
        
        var arguments = LabeledExprListSyntax()
        let containerArguments = generator.autoregistrationContainerOrderedArguments()
        
        let locator = configuration.locator ?? .locator(forType: typeDeclaration)
        let scope = configuration.scope ?? .automatic(forType: typeDeclaration)
        let rawEagerness = ".\(configuration.eagerness.caseName)"
        
        let rawValues: [AutoregisterableDependencyCodeGenerator.Arguments : String] = [
            .dependencyLocator : locator.rawValue,
            .dependencyScope : scope.rawValue,
            .dependencyEagerness : rawEagerness
        ]
        
        for argumentIndexPair in containerArguments.enumerated() {
            let containerArgument = argumentIndexPair.element
            let isLast = argumentIndexPair.offset >= containerArguments.count - 1
            
            guard let value = rawValues[containerArgument] else {
                continue
            }
            
            let argument = LabeledExprSyntax(
                leadingTrivia: .newline,
                label: TokenSyntax(stringLiteral: containerArgument.rawValue),
                colon: .colonToken(),
                expression: ExprSyntax(stringLiteral: value),
                trailingComma: isLast ? .none : .commaToken()
            )
            
            arguments.append(argument)
        }
        
        return FunctionCallExprSyntax(
            calledExpression: ExprSyntax(stringLiteral: type),
            leftParen: .leftParenToken(),
            arguments: arguments,
            rightParen: .rightParenToken(leadingTrivia: .carriageReturn),
            trailingClosure: dependencyFactoryTrailingClosureSyntax()
        )
    }
    
    private func dependencyFactoryTrailingClosureSyntax() -> ClosureExprSyntax {
        return ClosureExprSyntax(
            leadingTrivia: nil,
            leftBrace: .leftBraceToken(),
            signature: dependencyFactoryClosureCaptureSuntax(),
            statements: dependencyFactoryClosureBody(),
            rightBrace: .rightBraceToken(),
            trailingTrivia: nil
        )
    }
    
    private func dependencyFactoryClosureCaptureSuntax() -> ClosureSignatureSyntax? {
        let parameters = preferredInitializer.signature.parameterClause.parameters
        
        guard parameters.count > 0 else {
            return nil
        }
        
        var closureParameters = ClosureShorthandParameterListSyntax()
        
        for parameterIndexPair in parameters.enumerated() {
            let parameter = parameterIndexPair.element
            let isLast = parameterIndexPair.offset >= parameters.count - 1
            let closureParameter = ClosureShorthandParameterSyntax(
                name: parameter.secondName ?? parameter.firstName,
                trailingComma: isLast ? .none : .commaToken()
            )
                        
            closureParameters.append(closureParameter)
        }
        
        return ClosureSignatureSyntax(
            parameterClause: ClosureSignatureSyntax.ParameterClause(closureParameters)
        )
    }
    
    private func dependencyFactoryClosureBody() -> CodeBlockItemListSyntax {
        var arguments = LabeledExprListSyntax()
        let parameters = preferredInitializer.signature.parameterClause.parameters
        
        for parameterIndexPair in parameters.enumerated() {
            let parameter = parameterIndexPair.element
            let isLast = parameterIndexPair.offset >= parameters.count - 1
            
            let label = parameter.firstName
            let value = parameter.secondName ?? parameter.firstName
            let invocationArgument = LabeledExprSyntax(
                leadingTrivia: .newline,
                label: label.trimmed,
                colon: .colonToken(),
                expression: ExprSyntax(
                    stringLiteral: value.trimmedDescription
                ),
                trailingComma: isLast ? .none : .commaToken()
            )
                        
            arguments.append(invocationArgument)
        }
        
        let function = FunctionCallExprSyntax(
            calledExpression: ExprSyntax(stringLiteral: typeDeclaration.trimmedDescription),
            leftParen: .leftParenToken(),
            arguments: arguments,
            rightParen: .rightParenToken(leadingTrivia: .carriageReturn)
        )
        
        var statements = CodeBlockItemListSyntax()
        statements.append(
            CodeBlockItemListSyntax.Element(
                item: .init(function)
            )
        )
        
        return statements
    }
}

fileprivate extension DependencyEagerness {
    
    var caseName: String {
        switch self {
        case .lazy:
            return "lazy"
        case .eager:
            return "eager"
        }
    }
}

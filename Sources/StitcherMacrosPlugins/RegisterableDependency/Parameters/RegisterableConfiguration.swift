//
//  RegisterableConfiguration.swift
//
//
//  Created by Αθανάσιος Κεφαλάς on 26/3/24.
//

import SwiftSyntax
import Stitcher

public struct RegisterableConfiguration {
    
    struct Locator {
        
        enum Kind {
            case name
            case type
            case value
            case custom
        }
        
        let kind: Kind
        let rawValue: String
        
        var types: [String]? {
            guard kind == .type,
                  let associatedValue = rawValue.parsingAssociatedValue() else {
                return nil
            }
            
            return associatedValue.split(
                separator: ",",
                whenNotPlacedIn: StringEnvelope.allCases
            )
            .map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
        }
        
        init?(rawValue: String) {
            self.rawValue = rawValue
            
            switch rawValue.parsingCaseName() {
            case "name":
                self.kind = .name
            case "type":
                self.kind = .type
            case "value":
                self.kind = .value
            default:
                self.kind = .custom
            }
        }
        
        private init(typeName: String) {
            self.rawValue = ".type(\(typeName).self)"
            self.kind = .type
        }
        
        static func locator<TypeDeclarationSyntax: TypeSyntaxProtocol>(
            forType type: TypeDeclarationSyntax
        ) -> Self {
            Locator(typeName: type.trimmedDescription)
        }
    }
    
    struct Scope {
        
        enum Kind {
            case instance
            case shared
            case singleton
            case managed
            case custom
        }
        
        let kind: Kind
        let rawValue: String
        
        init?(rawValue: String) {
            self.rawValue = rawValue
            
            switch rawValue.parsingCaseName() {
            case "instance":
                self.kind = .instance
            case "shared":
                self.kind = .shared
            case "singleton":
                self.kind = .singleton
            case "managed":
                self.kind = .managed
            default:
                return nil
            }
        }
        
        private init(automaticFor typeName: String) {
            self.kind = .custom
            self.rawValue = ".automatic(for: \(typeName).self)"
        }
        
        static func automatic<TypeDeclarationSyntax: TypeSyntaxProtocol>(
            forType type: TypeDeclarationSyntax
        ) -> Self {
            Scope(automaticFor: type.trimmedDescription)
        }
    }
    
    let locator: Locator?
    let scope: Scope?
    let eagerness: DependencyEagerness
    
    init() {
        self.locator = nil
        self.scope = nil
        self.eagerness = .lazy
    }
    
    init(
        locator: Locator?,
        scope: Scope?,
        eagerness: DependencyEagerness
    ) {
        self.locator = locator
        self.scope = scope
        self.eagerness = eagerness
    }
    
    static func parsing(syntax node: AttributeSyntax) throws -> Self {
        let parser = Parser()
        return try parser.parse(syntax: node)
    }
    
    struct Parser {
        
        private enum Context: String, Hashable, CaseIterable {
            case locator = "by"
            case scope = "scope"
            case eagerness = "eagerness"
            
            static func parsing(label: String?) -> Self? {
                allCases.first(where: { $0.rawValue == label })
            }
        }
        
        init() {}
        
        func parse(syntax node: AttributeSyntax) throws -> RegisterableConfiguration {
            var context: Context? = nil
            var parsedElements: [Context : [String]] = [:]
            
            guard let arguments = node.arguments else {
                return RegisterableConfiguration()
            }
            
            guard let argumentsExpressionList = arguments.as(LabeledExprListSyntax.self) else {
                throw RegisterableMacro.Diagnostic(code: .malformedArguments)
            }
            
            if argumentsExpressionList.isEmpty {
                return RegisterableConfiguration()
            }
            
            for labeledExpression in argumentsExpressionList {
                let value = labeledExpression.expression.trimmedDescription
                
                if let newContext = Context.parsing(label: labeledExpression.label?.trimmed.text) {
                    context = newContext
                }
                
                guard let context = context else {
                    throw RegisterableMacro.Diagnostic(code: .malformedArguments)
                }
                
                var elements = parsedElements[context] ?? []
                elements.append(value)
                
                parsedElements[context] = elements
            }
            
            return RegisterableConfiguration(
                locator: try parseLocator(rawValue: parsedElements[.locator] ?? []),
                scope: try parseScope(rawValue: parsedElements[.scope] ?? []),
                eagerness: try parseEagerness(rawValue: parsedElements[.eagerness] ?? [])
            )
        }
        
        private func parseLocator(
            rawValue: [String]
        ) throws -> Locator? {
            
            guard !rawValue.isEmpty else {
                return nil
            }
            
            guard let rawLocator = rawValue.first, rawValue.count == 1 else {
                throw RegisterableDiagnostic(code: .malformedArguments)
            }
            
            return Locator(rawValue: rawLocator)
        }
        
        private func parseScope(
            rawValue: [String]
        ) throws -> Scope? {
            
            guard !rawValue.isEmpty else {
                return nil
            }
            
            guard let rawScope = rawValue.first, rawValue.count == 1 else {
                throw RegisterableDiagnostic(code: .malformedArguments)
            }
            
            return Scope(rawValue: rawScope)
        }
        
        private func parseEagerness(
            rawValue: [String]
        ) throws -> DependencyEagerness {
            
            guard !rawValue.isEmpty else {
                return .lazy
            }
            
            guard let rawEagerness = rawValue.first?.parsingCaseName(), rawValue.count == 1 else {
                throw RegisterableDiagnostic(code: .malformedArguments)
            }
            
            switch rawEagerness {
            case "lazy":
                return .lazy
            case "eager":
                return .eager
            default:
                throw RegisterableDiagnostic(code: .malformedArguments)
            }
        }
    }
}

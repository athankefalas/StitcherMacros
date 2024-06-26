//
//  InjectedParametersConfiguration.swift
//
//
//  Created by Αθανάσιος Κεφαλάς on 24/3/24.
//

import SwiftSyntax
import Stitcher

struct InjectedParametersConfiguration {
    
    let parent: AttachedParentKind
    let generator: InjectionCodeGenerator
    let ignoredParameters: Set<IgnoredParameter>
    
    init() {
        self.parent = .classParent
        self.generator = InjectionCodeGenerators.defaultGenerator
        self.ignoredParameters = []
    }
    
    init(
        parent: AttachedParentKind,
        generator: InjectionCodeGenerator,
        ignoredParameters: Set<IgnoredParameter>
    ) {
        self.parent = parent
        self.generator = generator
        self.ignoredParameters = ignoredParameters
    }
    
    static func parsing(syntax node: AttributeSyntax) throws -> Self {
        let parser = Parser()
        return try parser.parse(syntax: node)
    }
    
    struct Parser {
        
        private enum Context: String, Hashable, CaseIterable {
            case parent = "parent"
            case generator = "strategy"
            case ignoredParameters = "ignoring"
            
            static func parsing(label: String?) -> Self? {
                allCases.first(where: { $0.rawValue == label })
            }
        }
     
        init(){}
        
        func parse(syntax node: AttributeSyntax) throws -> InjectedParametersConfiguration {
            var context: Context? = nil
            var parsedElements: [Context : [String]] = [:]
            
            guard let arguments = node.arguments else {
                return InjectedParametersConfiguration()
            }
            
            guard let argumentsExpressionList = arguments.as(LabeledExprListSyntax.self) else {
                throw InjectedParametersMacro.Diagnostic(code: .malformedArguments)
            }
            
            if argumentsExpressionList.isEmpty {
                return InjectedParametersConfiguration()
            }
            
            for labeledExpression in argumentsExpressionList {
                let value = labeledExpression.expression.trimmedDescription.removingEnvelope(.doubleQuotes)
                
                if let newContext = Context.parsing(label: labeledExpression.label?.trimmed.text) {
                    context = newContext
                }
                
                guard let context = context else {
                    throw InjectedParametersMacro.Diagnostic(code: .malformedArguments)
                }
                
                var elements = parsedElements[context] ?? []
                elements.append(value)
                
                parsedElements[context] = elements
            }
            
            return InjectedParametersConfiguration(
                parent: try parseParent(
                    rawValue: parsedElements[.parent] ?? []
                ),
                generator: try parseGenerator(
                    rawValue: parsedElements[.generator] ?? []
                ),
                ignoredParameters: try parseIgnoredArguments(
                    rawValue: parsedElements[.ignoredParameters] ?? []
                )
            )
        }
        
        private func parseParent(
            rawValue: [String]
        ) throws -> AttachedParentKind {
            
            guard rawValue.count <= 1 else {
                throw InjectedParametersMacro.Diagnostic(code: .malformedArguments)
            }
            
            guard let first = rawValue.first?.parsingCaseName() else {
                return .classParent
            }
            
            guard let parent = AttachedParentKind(rawValue: first) else {
                throw InjectedParametersMacro.Diagnostic(code: .malformedArguments)
            }
            
            return parent
        }
        
        private func parseGenerator(
            rawValue: [String]
        ) throws -> any InjectionCodeGenerator {
            
            if rawValue.isEmpty {
                return InjectionCodeGenerators.defaultGenerator
            }
            
            guard let rawName = rawValue.first?.parsingCaseName(),
                  rawValue.count == 1,
                  let name = InjectionCodeGenerators.Name.allCases.first(where: { $0.rawValue == rawName }) else {
                throw InjectedParametersDiagnostic(code: .malformedArguments)
            }
            
            return InjectionCodeGenerators.generator(named: name)
        }
        
        private func parseIgnoredArguments(
            rawValue: [String]
        ) throws -> Set<IgnoredParameter> {
            
            let sanitizedvalues = rawValue.map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
            
            guard sanitizedvalues.allSatisfy({ !$0.contains(" ") && !$0.contains("\t") && !$0.contains("\n") }) else {
                throw InjectedParametersMacro.Diagnostic(code: .malformedArguments)
            }
            
            return Set(sanitizedvalues.map({ IgnoredParameter(rawValue: $0) }))
        }
    }
}

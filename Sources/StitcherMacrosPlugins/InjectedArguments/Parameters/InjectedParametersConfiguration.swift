//
//  InjectedParametersConfiguration.swift
//
//
//  Created by Αθανάσιος Κεφαλάς on 24/3/24.
//

import SwiftSyntax

struct InjectedParametersConfiguration {
    
    let generator: InjectionCodeGenerator
    let ignoredParameters: Set<IgnoredParameter>
    
    init() {
        self.generator = InjectionCodeGenerator()
        self.ignoredParameters = []
    }
    
    init(generator: InjectionCodeGenerator, ignoredParameters: Set<IgnoredParameter>) {
        self.generator = generator
        self.ignoredParameters = ignoredParameters
    }
    
    struct Parser {
        
        private enum Context: String, Hashable, CaseIterable {
            case generator = "generator"
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
                throw InjectedArgumentsMacro.Diagnostic(code: .malformedArguments)
            }
            
            if argumentsExpressionList.isEmpty {
                return InjectedParametersConfiguration()
            }
            
            for labeledExpression in argumentsExpressionList {
                let value = labeledExpression.expression.trimmedDescription.removeEnvelope(of: "\"")
                
                if let newContext = Context.parsing(label: labeledExpression.label?.trimmed.text) {
                    context = newContext
                }
                
                guard let context = context else {
                    throw InjectedArgumentsMacro.Diagnostic(code: .malformedArguments)
                }
                
                var elements = parsedElements[context] ?? []
                elements.append(value)
                
                parsedElements[context] = elements
            }
            
            return InjectedParametersConfiguration(
                generator: try parseGenerator(
                    rawValue: parsedElements[.generator] ?? []
                ),
                ignoredParameters: try parseIgnoredArguments(
                    rawValue: parsedElements[.ignoredParameters] ?? []
                )
            )
        }
        
        private func parseGenerator(
            rawValue: [String]
        ) throws -> InjectionCodeGenerator {
            
            guard rawValue.count <= 1 else {
                throw InjectedArgumentsMacro.Diagnostic(code: .malformedArguments)
            }
            
            guard let first = rawValue.first else {
                return InjectionCodeGenerator()
            }
            
            return InjectionCodeGenerator(template: first)
        }
        
        private func parseIgnoredArguments(
            rawValue: [String]
        ) throws -> Set<IgnoredParameter> {
            
            let sanitizedvalues = rawValue.map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
            
            guard sanitizedvalues.allSatisfy({ !$0.contains(" ") && !$0.contains("\t") && !$0.contains("\n") }) else {
                throw InjectedArgumentsMacro.Diagnostic(code: .malformedArguments)
            }
            
            return Set(sanitizedvalues.map({ IgnoredParameter(rawValue: $0) }))
        }
    }
}

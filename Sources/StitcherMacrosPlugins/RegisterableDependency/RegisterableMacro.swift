//
//  RegisterableMacro.swift
//
//
//  Created by Αθανάσιος Κεφαλάς on 26/3/24.
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxBuilder
import SwiftCompilerPlugin

public struct RegisterableMacro: ExtensionMacro {
    typealias Diagnostic = RegisterableDiagnostic
    
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        
        let configuration = try RegisterableConfiguration.parsing(syntax: node)
        let initializer = try findPreferredInitializer(
            of: type,
            in: declaration
        )
        
        try validate(
            configuration: configuration,
            type: type,
            declaration: declaration
        )
        
        let conformances = ProtocolConformanceSyntax(
            protocols: protocols
        )
        
        let implementation = RegisterableDependencyImplementationSyntax(
            configuration: configuration,
            type: type,
            definition: declaration,
            preferredInitializer: initializer
        )
        
        return [
            ExtensionDeclSyntax(
                extendedType: type,
                inheritanceClause: InheritanceClauseSyntax(
                    inheritedTypes: conformances.syntax()
                ),
                memberBlock: implementation.syntax()
            )
        ]
    }
    
    private static func findPreferredInitializer(
        of type: some TypeSyntaxProtocol,
        in declaration: some DeclGroupSyntax
    ) throws -> InitializerDeclSyntax {
        
        let initializers = try findInitializers(
            of: type,
            in: declaration
        )
        
        if initializers.isEmpty {
            throw Diagnostic(code: .missingPreferredInitializer)
        }
        
        let declaredInitializers = initializers
            .filter({ !$0.attributes.containsMacro(.preferredInitializer) && !$0.attributes.contains(.disfavoredOverload()) })
        
        let preferredInitializers = initializers
            .filter({ $0.attributes.containsMacro(.preferredInitializer) })
        
        if preferredInitializers.isEmpty && declaredInitializers.count > 1 {
            throw Diagnostic(code: .multiplePreferredInitializersFound)
        }
        
        if let preferredInitializer = preferredInitializers.first {
            return preferredInitializer
        }
        
        if let declaredInitializer = declaredInitializers.first, declaredInitializers.count == 1 {
            return declaredInitializer
        }
        
        throw Diagnostic(code: .missingPreferredInitializer)
    }
    
    private static func findInitializers(
        of type: some TypeSyntaxProtocol,
        in declaration: some DeclGroupSyntax
    ) throws -> [InitializerDeclSyntax] {
        
        let memberDeclarations = declaration.memberBlock.members
            .map(\.trimmed.decl)
        
        return memberDeclarations
            .filter({ $0.kind == .initializerDecl })
            .compactMap({ $0.as(InitializerDeclSyntax.self)?.trimmed })
            .filter({ PreferredInitializerMacro.supports(initializer: $0) })
            .sorted { lhs, rhs in
                
                let lhsParameterCount = lhs.signature.parameterClause.parameters.count
                let rhsParameterCount = rhs.signature.parameterClause.parameters.count
                let lhsIsPreferredInitializer = lhs.attributes.containsMacro(.preferredInitializer)
                let rhsIsPreferredInitializer = rhs.attributes.containsMacro(.preferredInitializer)
                
                if lhsIsPreferredInitializer && rhsIsPreferredInitializer {
                    return lhsParameterCount < rhsParameterCount
                }
                
                if lhsIsPreferredInitializer || rhsIsPreferredInitializer {
                    return lhsIsPreferredInitializer
                }
                
                return lhsParameterCount < rhsParameterCount
            }
    }
    
    // MARK: Validation
    
    private static func validate(
        configuration: RegisterableConfiguration,
        type: some TypeSyntaxProtocol,
        declaration: some DeclGroupSyntax
    ) throws {
        try validateTypeHierarchy(configuration: configuration, declaration: declaration)
    }
    
    private static func validateTypeHierarchy(
        configuration: RegisterableConfiguration,
        declaration: some DeclGroupSyntax
    ) throws {
        
        guard let locatorTypes = configuration.locator?.types else {
            return
        }
        
        guard let inheritanceClause = declaration.inheritanceClause else {
            throw Diagnostic(code: .malformedArgumentsUnrelatedLocatorTypes)
        }
        
        let inheritedTypes = Set(inheritanceClause.inheritedTypes.map({ $0.type.trimmedDescription }))
        
        for locatorType in locatorTypes {
            let nominalTypeName = locatorType.removingSuffix(".self")
            
            if !inheritedTypes.contains(nominalTypeName) {
                throw Diagnostic(code: .malformedArgumentsUnrelatedLocatorTypes)
            }
        }
    }
}

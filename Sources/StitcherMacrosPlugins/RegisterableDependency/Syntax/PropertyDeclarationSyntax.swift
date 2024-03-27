//
//  PropertyDeclarationSyntax.swift
//
//
//  Created by Αθανάσιος Κεφαλάς on 27/3/24.
//

import SwiftSyntax
import SwiftSyntaxBuilder

struct PropertyDeclarationSyntax {
    
    enum Attachment: String, Hashable {
        case type = "static"
        case instance = ""
    }
    
    enum Mutability: String, Hashable {
        case constant = "let"
        case variable = "var"
    }
    
    enum AccessModifier: String, Hashable, CaseIterable {
        case publicModifier = "public"
        case packageModifier = "package"
        case internalModifier = "internal"
        case fileprivateModifier = "fileprivate"
        case privateModifier = "private"
        case defaultModifier = ""
        
        static func fromType(
            typeDeclaration: some DeclGroupSyntax
        ) -> Self {
            
            let modifiers = Set(typeDeclaration.trimmed.modifiers.map({ $0.trimmed.name.text }))
            
            if let match = allCases.first(where: { modifiers.contains($0.rawValue) }) {
                return match
            }
            
            return .defaultModifier
        }
    }
    
    private let attachment: Attachment
    private let mutability: Mutability
    private let accessModifier: AccessModifier
    private let propertyType: String?
    private let propertyName: String
    private let propertyValue: InitializerClauseSyntax
    
    private var rawModifiers: Set<String> {
        Set([accessModifier.rawValue, attachment.rawValue].filter({ $0.count > 0 }))
    }
    
    init(
        attachment: Attachment,
        mutability: Mutability,
        accessModifier: AccessModifier,
        propertyType: String?,
        propertyName: String,
        propertyValue: InitializerClauseSyntax
    ) {
        self.attachment = attachment
        self.mutability = mutability
        self.accessModifier = accessModifier
        self.propertyType = propertyType
        self.propertyName = propertyName
        self.propertyValue = propertyValue
    }
    
    func syntax(
        leadingTrivia: Trivia? = .newline,
        trailingTrivia: Trivia? = nil
    ) -> VariableDeclSyntax {
        var modifiers = DeclModifierListSyntax()
        
        for rawModifier in rawModifiers {
            modifiers.append(
                DeclModifierListSyntax.Element(
                    name: TokenSyntax(stringLiteral: rawModifier)
                )
            )
        }
        
        var bindings = PatternBindingListSyntax()
        bindings.append(
            PatternBindingListSyntax.Element(
                pattern: IdentifierPatternSyntax(
                    identifier: TokenSyntax(stringLiteral: propertyName)
                ),
                typeAnnotation: typeAnnotationSyntax(),
                initializer: propertyValue
            )
        )
        
        return VariableDeclSyntax(
            leadingTrivia: leadingTrivia,
            modifiers: modifiers,
            bindingSpecifier: TokenSyntax(
                stringLiteral: mutability.rawValue
            ),
            bindings: bindings,
            trailingTrivia: trailingTrivia
        )
    }
    
    private func typeAnnotationSyntax() -> TypeAnnotationSyntax? {
        guard let propertyType else {
            return nil
        }
        
        return TypeAnnotationSyntax(
            type: TypeSyntax(stringLiteral: propertyType)
        )
    }
    
    func memberWrappedSyntax(
        leadingTrivia: Trivia? = nil,
        trailingTrivia: Trivia? = nil
    ) -> MemberBlockItemSyntax {
        
        return MemberBlockItemSyntax(
            leadingTrivia: leadingTrivia,
            decl: syntax(),
            trailingTrivia: trailingTrivia
        )
    }
}

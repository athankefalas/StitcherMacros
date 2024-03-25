//
//  Attributes.swift
//
//
//  Created by Αθανάσιος Κεφαλάς on 24/3/24.
//

import SwiftSyntax

fileprivate let disfavoredOverloadAttribute: AttributeSyntax = "@_disfavoredOverload"

extension AttributeListSyntax.Element {
    
    static func disfavoredOverload() -> Self {
        return .attribute(disfavoredOverloadAttribute)
    }
}

extension AttributeListSyntax {
    
    mutating func addMacroDirective(_ macro: DefinedMacro) {
        var macroSyntax = AttributeSyntax(stringLiteral: macro.rawValue)
        macroSyntax.leadingTrivia = .newline
        
        let macroAttribute = AttributeListSyntax.Element.attribute(macroSyntax)
        self.append(macroAttribute)
    }
    
    func addingMacroDirective(_ macro: DefinedMacro) -> Self {
        var mutableSelf = self
        mutableSelf.addMacroDirective(macro)
        
        return mutableSelf
    }
    
    mutating func removeMacroDirective(_ macro: DefinedMacro) {
        self = filter({ !$0.trimmed.description.contains(macro.rawValue) })
    }
    
    func removingMacroDirective(_ macro: DefinedMacro) -> Self {
        self.filter({ !$0.trimmed.description.contains(macro.rawValue) })
    }
    
    mutating func addDisfavoredOverload() {
        
        guard !self.contains(where: { $0.trimmed.description == disfavoredOverloadAttribute.description }) else {
            return
        }
        
        self.append(.disfavoredOverload())
    }
    
    func addingDisfavoredOverload() -> Self {
        var mutableSelf = self
        mutableSelf.addDisfavoredOverload()
        
        return mutableSelf
    }
}

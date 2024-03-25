//
//  Attributes.swift
//
//
//  Created by Αθανάσιος Κεφαλάς on 24/3/24.
//

import SwiftSyntax

//AttributeListSyntax

fileprivate let disfavoredOverloadAttribute: AttributeSyntax = "@_disfavoredOverload"

extension AttributeListSyntax.Element {
    
    static func disfavoredOverload() -> Self {
        return .attribute(disfavoredOverloadAttribute)
    }
}

extension AttributeListSyntax {
    
    func removingMacroDirective(_ macro: String) -> Self {
        self.filter({ !$0.trimmed.description.contains(macro) })
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

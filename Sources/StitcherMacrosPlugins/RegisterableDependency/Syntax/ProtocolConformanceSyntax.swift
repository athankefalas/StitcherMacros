//
//  ProtocolConformanceSyntax.swift
//
//
//  Created by Αθανάσιος Κεφαλάς on 26/3/24.
//

import SwiftSyntax

public struct ProtocolConformanceSyntax {
    
    private let protocols: [TypeSyntax]
    
    init(protocols: [TypeSyntax]) {
        self.protocols = protocols
    }
    
    func syntax() -> InheritedTypeListSyntax {
        var conformingTypes = InheritedTypeListSyntax()
        
        for protocolKindIndexPair in protocols.enumerated() {
            let protocolKind = protocolKindIndexPair.element
            var inheritanceElement = InheritedTypeListSyntax.Element(type: protocolKind)
            
            if protocolKindIndexPair.offset < protocols.count - 1 {
                inheritanceElement.trailingComma = .commaToken()
            }
            
            conformingTypes.append(inheritanceElement)
        }
        
        return conformingTypes
    }
}

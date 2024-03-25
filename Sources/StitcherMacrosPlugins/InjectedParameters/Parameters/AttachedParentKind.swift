//
//  AttachedParentKind.swift
//
//
//  Created by Αθανάσιος Κεφαλάς on 25/3/24.
//

import Foundation

enum AttachedParentKind: String, CaseIterable {
    case actorParent
    case classParent
    case enumParent
    case structParent
    
    var usesReferenceSemantics: Bool {
        self == .actorParent || self == .classParent
    }
}

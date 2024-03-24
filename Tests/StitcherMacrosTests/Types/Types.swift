//
//  Types.swift
//
//
//  Created by Αθανάσιος Κεφαλάς on 24/3/24.
//

import Foundation

// Classes

class Letter {
    
    let one: One
    
    init(one: One) {
        self.one = one
    }
}

// Structs

struct One {
    let rawValue: Int
    
    init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

struct Two {
    let rawValue: Int
    
    init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

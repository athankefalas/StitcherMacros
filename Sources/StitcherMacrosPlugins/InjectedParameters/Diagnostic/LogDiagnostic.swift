//
//  LogDiagnostic.swift
//
//
//  Created by Αθανάσιος Κεφαλάς on 25/3/24.
//

import Foundation
import SwiftSyntaxMacros

struct LogDiagnostic: Error, CustomStringConvertible {
    
    let message: String
    
    var description: String {
        message
    }
    
    init(_ message: String) {
        self.message = message
    }
}

extension Macro {
    
    static func log(_ message: String) throws {
        throw LogDiagnostic(message)
    }
}

//
//  Utils.swift
//
//
//  Created by Αθανάσιος Κεφαλάς on 25/3/24.
//

import Foundation

extension String {
    
    func simplifyingTrivia() -> String {
        self.replacingOccurrences(of: "\t", with: "    ")
            .replacingOccurrences(of: "  ", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
    }
}

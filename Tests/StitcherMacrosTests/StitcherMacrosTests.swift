import XCTest
import StitcherMacros
import SwiftSyntaxMacros

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling.
// Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(StitcherMacrosPlugins)
@testable import StitcherMacrosPlugins

let testMacros: [String: Macro.Type] = [
    "InjectedParameters": InjectedParametersMacro.self,
    "PreferredInitializer": PreferredInitializerMacro.self,
    "Registerable" : RegisterableMacro.self
]
#endif

final class StitcherMacrosTests: XCTestCase {
    
    func test() {
        XCTAssert(true)
    }
}

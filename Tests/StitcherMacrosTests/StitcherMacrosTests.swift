import SwiftSyntaxMacros
import XCTest
import StitcherMacros

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling.
// Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(StitcherMacrosPlugins)
import StitcherMacrosPlugins

let testMacros: [String: Macro.Type] = [
    "InjectedParameters": InjectedParametersMacro.self,
]
#endif

final class StitcherMacrosTests: XCTestCase {
    
    func test() {
        XCTAssert(true)
    }
}

class Temp {
        
    let one: One
    
    @InjectedParameters(generator: "try! TestFactory.provide(type: {{PARAMETER_TYPE}}.self)")
    init(one: One) {
        self.one = one
    }
    
}

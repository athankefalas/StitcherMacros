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
    
#if canImport(StitcherMacrosPlugins)
    func test_parsing() {
    }
#endif
}

protocol Fake {}
protocol OtherFake {}

@Registerable(by: .name("nAmE"), scope: .instance, eagerness: .lazy)
public class AD: Fake {
    
    private init(a: Int, b ba: Int) {}
}

class Asdf {
    
    static let dependencyName: DependencyLocator = .name("nAmE")
    
    static let dependencyRegistration = GeneratedDependencyRegistration(
        locator: .name("nAmE"),
        scope: .instance,
        eagerness: .lazy
    ) {
        Asdf()
    }
    
    private init() {}
}
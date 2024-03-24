import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import StitcherMacros

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling.
// Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(StitcherMacrosPlugins)
import StitcherMacrosPlugins

let testMacros: [String: Macro.Type] = [
    "InjectedArguments": InjectedArgumentsMacro.self,
]
#endif

final class StitcherMacrosTests: XCTestCase {
    func testMacro() throws {
        #if canImport(StitcherMacrosMacros)
        assertMacroExpansion(
            """
            #stringify(a + b)
            """,
            expandedSource: """
            (a + b, "a + b")
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testMacroWithStringLiteral() throws {
        #if canImport(StitcherMacrosMacros)
        assertMacroExpansion(
            #"""
            #stringify("Hello, \(name)")
            """#,
            expandedSource: #"""
            ("Hello, \(name)", #""Hello, \(name)""#)
            """#,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func test_playground() {
        let a = Alpha()
        a.foo(a: 1, b: 2)
        a.foo(b: 3)
    }
}

func make<T>(type: T.Type) -> T {
    let typeName = "\(type)"
    
    if typeName == "Int" {
        return 8 as! T
    }
    
    fatalError()
}

class Alpha {
    
    var a = 0
    
    @InjectedArguments(
        generator: "make(type:{{PARAMETER_TYPE}}.self)",
        ignoring: "b"
    )
    func foo(a: Int, b: Int) {
        print("Foo \(a) \(b)")
    }
    
    func test(param: Any? = nil) {
//        foo(1)
    }
}

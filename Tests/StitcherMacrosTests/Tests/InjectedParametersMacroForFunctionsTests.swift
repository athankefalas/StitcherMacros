//
//  InjectedParametersMacroForFunctionsTests.swift
//  
//
//  Created by Αθανάσιος Κεφαλάς on 24/3/24.
//

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


final class InjectedParametersMacroForFunctionsTests: XCTestCase {

    func test_injectedParameters() {
        assertMacroExpansion(
"""

struct Container {

    @InjectedArguments(generator: "GENERATED_{{PARAMETER_TYPE}}")
    func foo(one: One) {}
}

""",
expandedSource:
"""

struct Container {
    func foo(one: One) {}

    @_disfavoredOverload
    func foo() {
        foo(one: GENERATED_One)
    }
}

""",
macros: testMacros
        )
    }
    
    func test_injectedParameters_async() {
        assertMacroExpansion(
"""

struct Container {

    @InjectedArguments(generator: "GENERATED_{{PARAMETER_TYPE}}")
    func foo(one: One) async {}
}

""",
expandedSource:
"""

struct Container {
    func foo(one: One) async {}

    @_disfavoredOverload
    func foo() async  {
        await foo(one: GENERATED_One)
    }
}

""",
macros: testMacros
        )
    }
    
    func test_injectedParameters_throws() {
        assertMacroExpansion(
"""

struct Container {

    @InjectedArguments(generator: "GENERATED_{{PARAMETER_TYPE}}")
    func foo(one: One) throws {}
}

""",
expandedSource:
"""

struct Container {
    func foo(one: One) throws {}

    @_disfavoredOverload
    func foo() throws  {
        try foo(one: GENERATED_One)
    }
}

""",
macros: testMacros
        )
    }
    
    func test_injectedParameters_asyncThrows() {
        assertMacroExpansion(
"""

struct Container {

    @InjectedArguments(generator: "GENERATED_{{PARAMETER_TYPE}}")
    func foo(one: One) async throws {}
}

""",
expandedSource:
"""

struct Container {
    func foo(one: One) async throws {}

    @_disfavoredOverload
    func foo() async throws  {
        try await foo(one: GENERATED_One)
    }
}

""",
macros: testMacros
        )
    }
    
    func test_injectedParameters_ignoringParameter() {
        assertMacroExpansion(
"""

struct Container {

    @InjectedArguments(generator: "GENERATED_{{PARAMETER_TYPE}}", ignoring: "other")
    func foo(one: One, other: Other) {}
}

""",
expandedSource:
"""

struct Container {
    func foo(one: One, other: Other) {}

    @_disfavoredOverload
    func foo(other: Other) {
        foo(one: GENERATED_One, other: other)
    }
}

""",
macros: testMacros
        )
    }
    
    func test_injectedParameters_ignoringUnknownParameter() {
        assertMacroExpansion(
"""

struct Container {

    @InjectedArguments(generator: "GENERATED_{{PARAMETER_TYPE}}", ignoring: "other_")
    func foo(one: One, other: Other) {}
}

""",
expandedSource:
"""

struct Container {
    func foo(one: One, other: Other) {}
}

""",
diagnostics: [
    DiagnosticSpec(
        message: "Malformed arguments. Ignored parameter 'other_' does not match a known parameter name.",
        line: 4,
        column: 5
    )
],
macros: testMacros
        )
    }

}

#endif

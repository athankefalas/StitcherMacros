import SwiftCompilerPlugin
import SwiftSyntaxMacros

/// Version: 0.9.1

@main
struct StitcherMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        InjectedParametersMacro.self,
        PreferredInitializerMacro.self
    ]
}

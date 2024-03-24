import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct StitcherMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        InjectedArgumentsMacro.self
    ]
}

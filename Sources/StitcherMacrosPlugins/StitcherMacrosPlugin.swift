import SwiftCompilerPlugin
import SwiftSyntaxMacros

/// Version: 0.9.0

@main
struct StitcherMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        InjectedParametersMacro.self,
        PreferredInitializerMacro.self
    ]
}

// Client
/*
 
import StitcherMacrosPlugins

/// The kind of parent an attached peer macro has.
public enum AttachedParentKind {
    case actorParent
    case classParent
    case enumParent
    case structParent
}

/// Creates a copy of the function or initializer it is attached to, that uses automatically injected arguments.
///
/// - Parameters:
///   - parentKind: The kind of the enclosing type. This can be useful when applying this macro to initializers.
///   - generator: A code generation template used to generate the injection code.
///   - ignoredParameters: The names of  the function or initializer parameters that should **not** be automatically injected.
@attached(peer, names: arbitrary)
public macro InjectedParameters(
    parent: AttachedParentKind = .classParent,
    generator: String = "stitcherByType",
    ignoring ignoredArguments: String...
) = #externalMacro(
    module: "StitcherMacrosPlugins",
    type: "InjectedParametersMacro"
)

@attached(peer)
public macro PreferredInitializer() = #externalMacro(
    module: "StitcherMacrosPlugins",
    type: "PreferredInitializerMacro"
)

*/

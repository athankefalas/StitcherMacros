import StitcherMacrosPlugins


/// Creates a copy of the function or initializer it is attached to, that uses automatically injected arguments.
///
/// - Parameters:
///   - generator: A code generation template used to generate the injection code.
///   - ignoredParameters: The names of  the function or initializer parameters that should **not** be automatically injected.
@attached(peer, names: arbitrary)
public macro InjectedParameters(
    generator: String = "stitcher",
    ignoring ignoredArguments: String...
) = #externalMacro(module: "StitcherMacrosPlugins", type: "InjectedParametersMacro")

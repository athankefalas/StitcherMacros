import StitcherMacrosPlugins

@attached(peer, names: arbitrary)
public macro InjectedArguments(
    generator: String = "stitcher",
    ignoring arguments: String...
) = #externalMacro(module: "StitcherMacrosPlugins", type: "InjectedArgumentsMacro")

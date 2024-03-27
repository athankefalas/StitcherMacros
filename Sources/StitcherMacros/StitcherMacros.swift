//
//  StitcherMacros.swift
//
//
//  Created by Αθανάσιος Κεφαλάς on 25/3/24.
//

@_exported import Stitcher

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
    generator: InjectionCodeGenerators.Name = .stitcherByType,
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

@attached(
    extension,
    conformances: RegisterableDependency, AutoregisterableDependency,
    names: named(dependencyRegistration), named(dependencyName), named(dependencyValue)
)
public macro Registerable(
    by locator: DependencyLocator = .name(""),
    scope: DependencyScope = .singleton,
    eagerness: DependencyEagerness = .lazy
) = #externalMacro(
    module: "StitcherMacrosPlugins",
    type: "RegisterableMacro"
)


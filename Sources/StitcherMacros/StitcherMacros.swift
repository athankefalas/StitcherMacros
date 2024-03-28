//
//  StitcherMacros.swift
//
//
//  Created by Αθανάσιος Κεφαλάς on 25/3/24.
//

@_exported import Stitcher


// MARK: InjectedParameters


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
///   - generator: The code generation template used to generate the injection code.
///   - ignoredParameters: The names of  the function or initializer parameters that should **not** be automatically injected.
///
/// - Note: When attaching this macro on the initializer of a `struct` or an `enum` the type semantics must be provided. This is
/// required to correctly define the generated initializer in Swift versions lower than 6.0. If the parent type is not provided, the macro assumes
/// that by default it was attached to a reference type in Swift `<` 6.0.
@attached(peer, names: arbitrary)
public macro InjectedParameters(
    parent: AttachedParentKind = .classParent,
    generator: InjectionCodeGenerators.Name = .stitcherByType,
    ignoring ignoredArguments: String...
) = #externalMacro(
    module: "StitcherMacrosPlugins",
    type: "InjectedParametersMacro"
)


// MARK: PreferredInitializer


/// Marks the initializer it is attached to as the preferred initializer for instantiating this type.
/// - Note: A preferred initializer must be a non-generic, synchronous, non-failable, non-throwing initializer.
@attached(peer)
public macro PreferredInitializer() = #externalMacro(
    module: "StitcherMacrosPlugins",
    type: "PreferredInitializerMacro"
)


// MARK: Registerable


/// Makes this dependency type registerable by automatically adding a generated registration as a static member.
///
/// - Parameters:
///    - locator: The locator used to query the represented dependency in a dependency container. If omitted, the
///    dependency will be registered by it's nominal type.
///    - scope: The scope of the represented dependency. If omitted, the `.automatic` scope will be used.
///    - eagernees: The eagerness of the represented dependency. If omitted, the `.lazy` eagerness will be used.
///
/// - Note: The dependency will be instantiated by it's preferred initializer if one is marked as such. If no preferred initializer
///         can be located or *inferred* an appropriate diagnostic will be emitted. For supported initalizer types see ``PreferredInitializer()``.
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


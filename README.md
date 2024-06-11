# Stitcher Macros

<!-- # Badges -->
[![License](https://img.shields.io/github/license/athankefalas/StitcherMacros)](https://github.com/athankefalas/StitcherMacros/LICENSE)
[![Release](https://img.shields.io/github/v/release/athankefalas/StitcherMacros)](https://github.com/athankefalas/StitcherMacros/releases/tag/v1.1.0)

A support package for [Stitcher](https://github.com/athankefalas/Stitcher.git) that defines meta programming utilities using Swift macros, enabling automatic parameter injection for functions and initializers as well as utilities for automatic dependency registration.

Contents:
- [Stitcher Macros](#stitcher-macros)
  - [✔️ Minimum Requirements](#️-minimum-requirements)
  - [🧰 Features](#-features)
  - [📦 Installation](#-installation)
    - [Swift Package](#swift-package)
    - [Manually](#manually)
  - [📋 Library Overview](#-library-overview)
    - [Parameter Injection](#parameter-injection)
      - [Configuration](#configuration)
        - [Parent Kind](#parent-kind)
        - [Strategy](#strategy)
        - [Ignored Parameters](#ignored-parameters)
      - [Supported Initializers / Functions](#supported-initializers--functions)
    - [Preferred Initialiser](#preferred-initialiser)
      - [Supported Initializers](#supported-initializers)
    - [Dependency Registration](#dependency-registration)
      - [Configuration](#configuration-1)
        - [Locator](#locator)
        - [Scope](#scope)
        - [Eagerness](#eagerness)
        - [Preferred Initializer](#preferred-initializer)
    - [Autoregistered Dependency Group](#autoregistered-dependency-group)
      - [Adding Sourcery](#adding-sourcery)
  - [🐞 Issues and Feature Requests](#-issues-and-feature-requests)


## ✔️ Minimum Requirements

StitcherMacros requires at least **iOS 13, macOS 10.15, tvOS 13** or **watchOS 6** and **Swift version 5.9**.

## 🧰 Features

- Automatic generation of functions and initializers with injected parameters providing an easy way to implement parameter injection.
- Automatic generation of registrations for dependencies.
- Automatic generation of registered dependency groups.

## 📦 Installation

StitcherMacros will automatically install and export [Stitcher](https://github.com/athankefalas/Stitcher.git) when installed.

### Swift Package

You may add Stitcher as a Swift Package dependency using Xcode 11.0 or later, by selecting `File > Swift Packages > Add Package Dependency...` or `File > Add packages...` in Xcode 13.0 and later, and adding the url below:

    https://github.com/athankefalas/StitcherMacros.git

### Manually 

You may also install this library manually by downloading the `StitcherMacros` project and including it in your project.

## 📋 Library Overview

A few of the items discussed in this section are predicated to being familiar with the basic concepts defined in the [Stitcher](https://github.com/athankefalas/Stitcher.git) library.

### Parameter Injection

Parameter injection refers to the practice of injecting the dependencies of a type as arguments in it's initializer or when invoking a function. In order to automatically generate initializers or functions, and having their parameters automatically injected by `Stitcher`, the targeted `init` or `func` declaration must be attributed with the `@InjectedParameters` macro.

```swift

class UploadService {
    
    private let networkingSession: NetworkingSession
    
    @InjectedParameters
    init(networkingSession: NetworkingSession) {
        self.networkingSession = networkingSession
    }
}

```

Which will be expanded to:

```swift

class UploadService {
    
    private let networkingSession: NetworkingSession
    
    @InjectedParameters
    init(networkingSession: NetworkingSession) {
        self.networkingSession = networkingSession
    }

    /// Automatically generated convenience initializer
    convenience init() {
        self.init(
            networkingSession: try! DependencyGraph.inject(
                byType: NetworkingSession.self
            )
        )
    }
}

```

Similarly the same pattern can be used with a function with some, or all of the parameters injected:

```swift

class UploadService {
    
    @InjectedParameters(ignoring: "file")
    func upload(file: URL, networkingSession: NetworkingSession) {}
}

```

Which will expand to the following:

```swift

class UploadService {
    
    @InjectedParameters(ignoring: "file")
    func upload(file: URL, networkingSession: NetworkingSession) {}

    /// Automatically generated function when macro is expanded:
    func upload(file: URL) {
        upload(
            file: file,
            networkingSession: try! DependencyGraph.inject(
                byType: NetworkingSession.self
            )
        )
    }
}

```

#### Configuration

The `InjectedParameters` macro can be configured with the following arguments:

* parent
  
  The kind of the parent type. This is used when defining initializers with injected parameters to determine the kind of initializer to create. By default, this option is set to a class parent which will create a convenience initializer. When using the macro on functions this argument is ignored.

* strategy
  
  The strategy used to inject dependencies in the generated initializer - function.

* ignoring
  
  The names of any ignored parameters that will not be injected and will instead be manually passed by the caller of the generated initializer - function. By default, none of the parameters present in the original declaration are ignored.

##### Parent Kind

The parent kind argument is used to control the macro output when using it with type initializers. For Swift versions `<=` 5.10, the compiler plugin engine does not provide information of the attached parent type for peer macros such as `InjectedParameters`. Consequently, when adding this macro to `struct` or `enum` initializers, in Swift versions older than 6, the parent type kind must also be provided to avoid compile time errors in the generated code.

Definition of acceptable parent kind values:
```swift
/// The kind of parent an attached peer macro has.
public enum AttachedParentKind {
    case actorParent
    case classParent
    case enumParent
    case structParent
}
```

The default value of this argument is `.classParent`, which is compatible with both `class` and `actor` types as they are both reference types and secondary initializers can be defined as `convenience` initializers in the same way.

Using `InjectedParameters` on a struct initializer:

```swift

struct Service {
    
    let repository: EntityRepository
    
    @InjectedParameters(parent: .structParent)
    init(repository: EntityRepository) {
        self.repository = repository
    }
}

```

##### Strategy

The strategy parameter controls how the dependency will be injected, either by type or by name. By default, all dependencies in generated code will be injected using the `.stitcherByType` strategy.

```swift

class Service {
    
    @InjectedParameters(strategy: .stitcherByType)
    func findAll(in repository: EntityRepository) -> [Entity] { [] }

    /// Automatically generated function when macro is expanded:
    func findAll() -> [Entity]  {
        findAll(
            in: try! DependencyGraph.inject(
                byType: EntityRepository.self
            )
        )
    }
    
    @InjectedParameters(strategy: .stitcherByType)
    func clear(_ repository: EntityRepository) {}

    /// Automatically generated function when macro is expanded:
    func clear() {
        clear(
            try! DependencyGraph.inject(
                byType: EntityRepository.self
            )
        )
    }
}

```

The `.stitcherByName` strategy may be used instead, in order to use injection by name. The name used during injection is the parameter name used in the original declaration.

```swift
class Service {
    
    @InjectedParameters(strategy: .stitcherByName)
    func findAll(in repository: EntityRepository) -> [Entity] { [] }
    
    /// Automatically generated function when macro is expanded:
    func findAll() -> [Entity]  {
        findAll(
            in: try! DependencyGraph.inject(
                byName: "repository"
            )
        )
    }

    @InjectedParameters(strategy: .stitcherByName)
    func clear(_ repository: EntityRepository) {}

    /// Automatically generated function when macro is expanded:
    func clear() {
        clear(
            try! DependencyGraph.inject(byName: "repository")
        )
    }
}

```

##### Ignored Parameters

The ignored parameter is a sequence of parameter names, that controls which of the initializer - function parameters will be ignored by the macro and be manually injected when invoking it.

```swift

class Service {
    
    @InjectedParameters(
        ignoring: "imageData", "attributes"
    )
    func upload(
        imageData: Data,
        convertedWith attributes: ImageAttributes = [],
        processingService: ImageProcessingService
    ) async throws {}
    
    /// Automatically generated function when macro is expanded:
    func upload(
        imageData: Data,
        convertedWith attributes: ImageAttributes = []
    ) async throws  {
        try await upload(
            imageData: imageData,
            convertedWith: attributes,
            processingService: try! DependencyGraph.inject(
                    byType: ImageProcessingService.self
                )
            )
    }
}

```

#### Supported Initializers / Functions

The `@InjectedParameters` macro supports all initializers - functions with non-generic parameters. If an initializer - function has a generic parameter and injection is required for the rest of the parameters, the generic parameter must be explicitly ignored using the `ignored` parameter.

Please note, that all generated initializers - functions are marked with the `@_disfavoredOverload` attribute and have a lower invocation priority than explicitly declared variants. Furthermore, a generated initializer that is also supported as the preferred initializer for the type, is automatically attributed with the `@PreferredInitializer` macro.

### Preferred Initialiser

The `@PreferredInitializer` macro is a marker attribute that declares which initializer should be used during automatic dependency registration generation by the `@Registerable` macro.

#### Supported Initializers

The preferred initializer supports any initializer that has no generic aguments, is not failable either by returning nil or throwing an error and is synchronous.

### Dependency Registration

The `@Registerable` macro can be used to automatically generate a dependency registration and attach it as a static member to the specified type, by conforming to the `RegisterableDependency` protocol.

```swift
@Registerable
class Service {
    
    init() {}
}

// Expanded macro:
extension Service: RegisterableDependency, AutoregisterableDependency {

    static let dependencyRegistration = GeneratedDependencyRegistration<Service>(
        locator: .type(Service.self),
        scope: .automatic(for: Service.self),
        eagerness: .lazy
    ) {
        Service()
    }
}
```

Furthermore, if the dependency is located by name or by an associated value the locator raw value is also automatically added to the conformance:

```swift
@Registerable(by: .name("service"))
class Service {
    
    init() {}    
}

// Expanded macro:
extension Service: RegisterableDependency, AutoregisterableDependency {

    static let dependencyName: String = "service"

    static let dependencyRegistration = GeneratedDependencyRegistration<Service>(
        locator: .name("service"),
        scope: .automatic(for: Service.self),
        eagerness: .lazy
    ) {
        Service()
    }
}

```

At runtime, the registraton can be added to a dependency container as follows:

```swift
@main
struct SomeApp: App {
    
    @Dependencies
    var container = DependencyContainer {
        // Dependency registration
        Service.dependencyRegistration
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

#### Configuration

The configuration of the `@Registerable` macro can be configured with the same options as the basic dependency registration using the `Dependency` struct.

##### Locator

Controls the way the dependency will be located. By default, the dependency will be located by it's type.

##### Scope

Controls the scope of the dependency. By default, the dependency scope that will be used is `.automatic()`.

##### Eagerness

Controls the eagerness of the dependency. By defaultm the dependency eagerness that will be used is `.lazy`.

##### Preferred Initializer

The `@PreferredInitializer` macro can be used to disambiguate which initializer will be selected for instantiating the dependency. In cases where multiple preferred initializers are found, the initializer with the smallest count of parameters will be selected.

### Autoregistered Dependency Group

Stitcher Macros includes a stencil template that can be optionally used with [Sourcery](https://github.com/krzysztofzablocki/Sourcery.git) in order to generate a dynamic dependency group at build time from all dependencies that are attributed with the `@Registerable` macro.

Furthermore, a completely custom stencil template can be used instead, either by targeting the `@Registerable` macro attribute or the `AutoregisterableDependency` protocol.

#### Adding Sourcery

1. Follow the steps in the [Sourcery](https://github.com/krzysztofzablocki/Sourcery.git) repository to install the command line tool or package plugin.
2. Create a sourcery configuration file. A simple example configuration file can be found at `Sourcery/sourcery.yml`.
3. Add Sourcery as a *build phase script* or a *commit phase triggered script*.
4. Add the autogenerated dependency group in a `DependencyContainer` to register the dependencies at runtime.

```swift
@main
struct SomeApp: App {
    
    @Dependencies
    var container = DependencyContainer {
        // Autogenerated Dependency registrations
        DependencyGroup.autoregisteredDependencies
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

The `Sourcery` integration is optional and the provided template and configuration are meant to serve as easy launch points, therefore it is recommended that they are adapted to better fit the build phase / pipeline of the specific project.

## 🐞 Issues and Feature Requests

If you have a problem with the library, or have a feature request please make sure to open an issue.

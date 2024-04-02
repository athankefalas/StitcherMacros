# Stitcher Macros

A support package for [Stitcher](https://github.com/athankefalas/Stitcher.git) that defines meta programming utilities using Swift macros, enabling automatic parameter injection for functions and initializers as well as utilities for automatic dependency registration.

Contents:
- [Stitcher Macros](#stitcher-macros)
  - [✔️ Minimum Requirements](#️-minimum-requirements)
  - [🧰 Features](#-features)
  - [📦 Installation](#-installation)
    - [Swift Package](#swift-package)
    - [Manually](#manually)
  - [Parameter Injection](#parameter-injection)
    - [Configuration](#configuration)
      - [Parent Kind](#parent-kind)
      - [Strategy](#strategy)
      - [Ignored Parameters](#ignored-parameters)
    - [Supported Initializers / Functions](#supported-initializers--functions)
  - [Preferred Initialiser](#preferred-initialiser)
    - [Supported Initializers](#supported-initializers)
  - [Dependency Registration](#dependency-registration)
  - [Automatic Dependency Group](#automatic-dependency-group)
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

## Parameter Injection

Parameter injection refers to the practice of injecting the dependencies of a type as arguments in it's initializer or when invoking a function. In order to automatically generate initializers or functions and having their arguments automatically injected by `Stitcher` the targeted `init` or `func` declaration must be decorated with the `@InjectedParameters` macro.

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

### Configuration

The `InjectedParameters` macro can be configured with the following arguments:

* parent
  
  The kind of the parent type. This is used when defining initializers with injected parameters to determine the kind of initializer to create. By default, this option is set to a class parent which will create a convenience initializer. When using the macro on functions this argument is ignored.

* strategy
  
  The strategy used to inject dependencies in the generated initializer - function.

* ignoring
  
  The names of any ignored parameters that will not be injected and will instead be manually passed by the caller of the generated initializer - function. By default none of the parameters present in the original declaration are ignored.

#### Parent Kind

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

#### Strategy

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

The `.stitcherByName` strategy may be used instead in order to use injection by name. The name used during injection is the parameter name used in the original declaration.

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

#### Ignored Parameters

TBD

### Supported Initializers / Functions

TBD

## Preferred Initialiser

TBD

### Supported Initializers

TBD

## Dependency Registration

TBD

## Automatic Dependency Group

TBD

## 🐞 Issues and Feature Requests

If you have a problem with the library, or have a feature request please make sure to open an issue.

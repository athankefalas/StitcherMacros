// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "StitcherMacros",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6),
        .macCatalyst(.v13),
        .visionOS(.v1)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "StitcherMacros",
            targets: ["StitcherMacros"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0"),
//        .package(url: "https://github.com/athankefalas/Stitcher.git", exact: "1.0.0"),
        .package(url: "https://github.com/athankefalas/Stitcher.git", branch: "feature/remove-combine")
    ],
    targets: [
        
        // Library that exposes a macro as part of its API, which is used in client programs.
        .target(
            name: "StitcherMacros",
            dependencies: ["Stitcher", "StitcherMacrosPlugins"]
        ),
        
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        // Macro implementation that performs the source transformation of a macro.
        .macro(
            name: "StitcherMacrosPlugins",
            dependencies: [
                "Stitcher",
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),

        // A test target used to develop the macro implementation.
        .testTarget(
            name: "StitcherMacrosTests",
            dependencies: [
                "StitcherMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        )
    ]
)

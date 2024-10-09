// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "fluor",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Fluor",
            targets: ["Fluor"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Fluor",
            dependencies: ["_Promise"]
        ),
        .target(
            name: "_Promise"
        ),
        .testTarget(
            name: "FluorTests",
            dependencies: ["Fluor", "_Promise"]
        ),
    ]
)

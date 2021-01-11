// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Extra",
    platforms: [
        .macOS(.v11),
    ],
    products: [
        .library(
            name: "Extra",
            targets: ["Extra"]),
        .library(
            name: "ExtraShared",
            targets: ["ExtraShared"]),
        .library(
            name: "NSXPCShared",
            targets: ["NSXPCShared"]),
        .library(
            name: "CXPCShared",
            targets: ["CXPCShared"]),
        .library(
            name: "Example",
            targets: ["Example"]),
    ],
    dependencies: [
        .package(url: "https://github.com/daniel-grumberg/CodableXPC.git",
                 from: "1.0.0")
    ],
    targets: [
        .target(
            name: "Extra",
            dependencies: ["CodableXPC"]),
        .testTarget(
            name: "ExtraTests",
            dependencies: ["Extra"]),
        .target(
            name: "Example",
            dependencies: [
                "Extra",
                "ExtraShared",
                "NSXPCShared",
                "CXPCShared",
            ],
            path: "Sources/Example/Example"),
        .target(
            name: "ExtraShared",
            dependencies: ["Extra"],
            path: "Sources/Example/ExtraShared"),
        .target(
            name: "NSXPCShared",
            path: "Sources/Example/NSXPCShared"),
        .target(
            name: "CXPCShared",
            path: "Sources/Example/CXPCShared"),
    ]
)

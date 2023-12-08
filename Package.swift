// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "Eip20Kit",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        .library(
            name: "Eip20Kit",
            targets: ["Eip20Kit"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/attaswift/BigInt.git", .upToNextMajor(from: "5.0.0")),
        .package(url: "https://github.com/groue/GRDB.swift.git", .upToNextMajor(from: "6.0.0")),
        .package(url: "https://github.com/horizontalsystems/EvmKit.Swift.git", .upToNextMajor(from: "2.0.5")),
        .package(url: "https://github.com/horizontalsystems/HsCryptoKit.Swift.git", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/horizontalsystems/HsExtensions.Swift.git", .upToNextMajor(from: "1.0.6")),
    ],
    targets: [
        .target(
            name: "Eip20Kit",
            dependencies: [
                "BigInt",
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "EvmKit", package: "EvmKit.Swift"),
                .product(name: "HsCryptoKit", package: "HsCryptoKit.Swift"),
                .product(name: "HsExtensions", package: "HsExtensions.Swift"),
            ]
        ),
    ]
)

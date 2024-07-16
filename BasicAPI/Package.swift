// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "template",
    platforms: [.macOS(.v14), .iOS(.v17), .tvOS(.v17)],
    products: [
        .executable(name: "App", targets: ["App"]),
    ],
    dependencies: [
        // Hummingbird base
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.0.0-rc.2"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
        // Database dependencies
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.9.2"),
        .package(url: "https://github.com/hummingbird-project/hummingbird-fluent.git", from: "2.0.0-beta.1")
    ],
    targets: [
        .executableTarget(name: "App",
                          dependencies: [
                            .product(name: "ArgumentParser", package: "swift-argument-parser"),
                            .product(name: "Hummingbird", package: "hummingbird"),
                            .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                            .product(name: "HummingbirdFluent", package: "hummingbird-fluent")
                          ],
                          path: "Sources/App"
                         ),
        .testTarget(name: "AppTests",
                    dependencies: [
                        .byName(name: "App"),
                        .product(name: "HummingbirdTesting", package: "hummingbird")
                    ],
                    path: "Tests/AppTests"
                   )
    ]
)

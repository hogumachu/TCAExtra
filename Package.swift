// swift-tools-version: 6.2

import CompilerPluginSupport
import PackageDescription

let package = Package(
  name: "TCAExtra",
  platforms: [
    .iOS(.v16),
    .macOS(.v13),
    .tvOS(.v16),
    .watchOS(.v9),
  ],
  products: [
    .library(
      name: "TCAExtra",
      targets: ["TCAExtra"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.24.1"),
    .package(url: "https://github.com/pointfreeco/swift-macro-testing", from: "0.6.3"),
    .package(url: "https://github.com/swiftlang/swift-syntax", from: "602.0.0"),
  ],
  targets: [
    .target(
      name: "TCAExtra",
      dependencies: [
        "TCAExtraMacros",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .macro(
      name: "TCAExtraMacros",
      dependencies: [
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
      ]
    ),
    .testTarget(
      name: "TCAExtraMacrosTests",
      dependencies: [
        "TCAExtraMacros",
        .product(name: "MacroTesting", package: "swift-macro-testing"),
      ]
    )
  ],
  swiftLanguageModes: [.v6]
)

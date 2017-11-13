// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "PathKit",
  products: [
      .library(name: "PathKit", targets: ["PathKit"]),
  ],
  dependencies: [
      .package(url: "https://github.com/kylef/Spectre.git", .upToNextMinor(from: "0.8.0"))
  ],
  targets: [
      .target(name: "PathKit", dependencies: [], path: "Sources"),
      .testTarget(name: "PathKitTests", dependencies: ["PathKit", "Spectre"], path: "Tests/PathKitTests")
  ]
)

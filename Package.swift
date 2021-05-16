// swift-tools-version:4.2
import PackageDescription

let package = Package(
  name: "PathKit",
  products: [
    .library(name: "PathKit", targets: ["PathKit"]),
  ],
  dependencies: [
    .package(url:"https://github.com/kylef/Spectre.git", .upToNextMinor(from:"0.10.0"))
  ],
  targets: [
    .target(name: "PathKit", dependencies: [], path: "Sources"),
    .testTarget(name: "PathKitTests", dependencies: ["PathKit", "Spectre"], path:"Tests/PathKitTests")
  ]
)

// swift-tools-version:4.2
import PackageDescription

let package = Package(
  name: "PathKit",
  products: [
    .library(name: "PathKit", targets: ["PathKit"]),
  ],
  dependencies: [
    .package(url:"../CDeps", .upToNextMajor(from: "1.0.1"))
  ],
  targets: [
    .target(name: "PathKit", dependencies: ["CDeps"], path: "Sources")
    //.testTarget(name: "PathKitTests", dependencies: ["PathKit", "Spectre"], path:"Tests/PathKitTests")
  ]
)

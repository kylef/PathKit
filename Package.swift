// swift-tools-version:4.2
import PackageDescription

let package = Package(
  name: "PathKit",
  products: [
    .library(name: "PathKit", targets: ["PathKit"]),
  ],
  dependencies: [
    .package(url:"https://github.com/kylef/Spectre.git", .upToNextMinor(from:"0.9.0")),
    .package(url:"https://github.com/michaeleisel/PathKitCExt.git", .branch("master"))
  ],
  targets: [
    .target(name: "PathKit", dependencies: ["PathKitCExt"], path: "Sources"),
    .testTarget(name: "PathKitTests", dependencies: ["PathKit", "Spectre"], path:"Tests/PathKitTests")
  ]
)

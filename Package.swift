import PackageDescription

let package = Package(
  name: "PathKit",
  dependencies: [
    // https://github.com/apple/swift-package-manager/pull/597
    .Package(url: "https://github.com/kylef/Spectre.git", majorVersion: 0, minor: 7),
  ]
)

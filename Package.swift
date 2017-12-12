// swift-tools-version:4.0
import Foundation
import PackageDescription

var isDevelopment: Bool {
    return ProcessInfo.processInfo.environment["PATHKIT_SWIFTPM_DEVELOPMENT"] == "YES"
}

func deps() -> [Package.Dependency] {
    var deps: [Package.Dependency] = []
    if isDevelopment {
        deps.append(
            .package(url: "https://github.com/kylef/Spectre.git", from: "0.8.0")
        )
    }
    return deps
}

let package = Package(
  name: "PathKit",
  pkgConfig: nil,
  products: [
    .library(name: "PathKit", targets: ["PathKit"]),
  ],
  dependencies: deps(),
  targets: {
    var t: [Target] = [.target(name: "PathKit", dependencies: [], path: "Sources")]
    if isDevelopment {
        t.append(
            .testTarget(name: "PathKitTests", dependencies: ["PathKit", "Spectre"])
        )
    }
    return t
  }()
)

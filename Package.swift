import PackageDescription

let package = Package(
  name: "PathKit",
  // Uncomment the following line once the public API for testDependencies is reimplemented
  //testDependencies: [
  dependencies: [
      .Package(url: "https://github.com/kylef/Spectre.git", majorVersion: 0, minor: 7)
  ],
  exclude: [
      "Tests"
  ]
)

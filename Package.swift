import PackageDescription

let package = Package(
  name: "PathKit",
  dependencies: [
      .Package(url: "https://github.com/Ponyboy47/Strings.git", majorVersion: 1)
  ],
  exclude: [
      "Tests"
  ]
)

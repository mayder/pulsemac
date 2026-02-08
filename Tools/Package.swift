// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "PulseMacTools",
  platforms: [.macOS(.v13)],
  products: [
    .executable(name: "swiftformat-tool", targets: ["SwiftFormatTool"])
  ],
  dependencies: [
    .package(url: "https://github.com/nicklockwood/SwiftFormat.git", from: "0.53.0")
  ],
  targets: [
    .executableTarget(
      name: "SwiftFormatTool",
      dependencies: [.product(name: "SwiftFormat", package: "SwiftFormat")]
    )
  ]
)

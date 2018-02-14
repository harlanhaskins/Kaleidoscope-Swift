// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Kaleidoscope",
    dependencies: [
      .package(url: "https://github.com/llvm-swift/LLVMSwift.git", from: "0.2.1")
    ],
    targets: [
      .target(name: "Kaleidoscope", dependencies: ["LLVM"])
    ]
)

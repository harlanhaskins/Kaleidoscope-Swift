import PackageDescription

let package = Package(
    name: "Kaleidoscope",
    dependencies: [
      .Package(url: "https://github.com/harlanhaskins/LLVMSwift.git", majorVersion: 0)
    ]
)

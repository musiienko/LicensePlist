// swift-tools-version:5.6
import PackageDescription

let package = Package(
  name: "abseil",
  products: [
    .library(name: "abseil", targets: ["abslWrapper"])
  ],
  targets: [
    .target(
        name: "abslWrapper",
        dependencies: ["absl"],
        path: "absl-Wrapper"
    ),
    .binaryTarget(
      name: "absl",
      url: "https://dl.google.com/firebase/ios/bin/abseil/1.2024072200.0/rc0/absl.zip",
      checksum: "72d4a03d002a063c6c99e04d9c0310ca830dfb9f39deb9a74ba689d6c1d89ac9"
    )
  ]
)

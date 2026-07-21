// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Factory",
    products: [
        .library(name: "Factory", targets: ["Factory"])
    ],
    targets: [
        .target(name: "Factory")
    ]
)

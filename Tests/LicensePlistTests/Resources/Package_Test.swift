// swift-tools-version: 6.2

import PackageDescription

let apiDependencies: [PackageDescription.Package.Dependency] = [
    .package(
        url: "https://github.com/apple/swift-protobuf.git",
        exact: "1.31.1"
    ),
    .package(
        url: "https://github.com/grpc/grpc-swift.git",
        exact: "1.26.1"
    ),
    .package(
        url: "https://github.com/apple/swift-nio.git",
        exact: "2.86.2"
    ),
    .package(
        url: "https://github.com/apple/swift-nio-http2.git",
        exact: "1.36.0"
    ),
    .package(
        url: "https://github.com/apple/swift-log.git",
        exact: "1.6.4"
    )
]

let internalDependencies: [PackageDescription.Package.Dependency] = [
    .package(
        url: "git@github.com:sumup/ios-cardvalidation-kit.git",
        exact: "1.0.2"
    ),
    .package(
        url: "git@github.com:sumup/ios-testing.git",
        exact: "1.2.0"
    ),
    .package(
        url: "git@github.com:sumup/observability-ios.git",
        exact: "0.36.0"
    ),
    .package(
        url: "git@github.com:sumup/observability-ios-integration.git",
        exact: "0.11.0"
    )
]

let testingDependencies: [PackageDescription.Package.Dependency] = [
    .package(
        url: "https://github.com/pointfreeco/swift-concurrency-extras.git",
        exact: "1.3.2"
    ),
    .package(
        url: "https://github.com/krzysztofzablocki/Difference.git",
        exact: "1.1.0"
    )
]

let externalDependencies: [PackageDescription.Package.Dependency] = [
    .package(
        url: "https://github.com/AppsFlyerSDK/AppsFlyerFramework.git",
        exact: "6.18.1"
    ),
    .package(
        url: "https://github.com/facebook/facebook-ios-sdk.git",
        exact: "18.0.3"
    ),
    .package(
        url: "https://github.com/firebase/firebase-ios-sdk.git",
        exact: "12.14.0"
    ),
    .package(
        url: "https://github.com/airbnb/lottie-ios.git",
        exact: "4.5.2"
    ),
    .package(
        url: "https://github.com/gonzalezreal/swift-markdown-ui.git",
        exact: "2.4.1"
    ),
    .package(
        url: "https://github.com/onevcat/Kingfisher.git",
        exact: "8.9.0"
    ),
    .package(
        url: "https://github.com/marmelroy/PhoneNumberKit.git",
        exact: "3.7.10"
    ),
    .package(
        url: "https://github.com/stripe/stripe-ios.git",
        exact: "24.9.0"
    ),
    .package(
        url: "https://github.com/Iterable/iterable-swift-sdk.git",
        exact: "6.7.2"
    ),
    .package(
        url: "https://github.com/onfido/onfido-ios-sdk.git",
        exact: "33.1.1"
    ),
    .package(
        url: "https://github.com/EntrustCorporation/IdvSDK-iOS.git",
        exact: "100.3.0"
    ),
    .package(
        url: "https://github.com/TrueLayer/TrueLayer-iOS-SDK.git",
        exact: "4.1.6"
    ),
    .package(
        url: "https://github.com/zendesk/sdk_messaging_ios.git",
        exact: "2.39.0"
    )
]

let package = Package(
    name: "ExternalDependencies",
    dependencies: apiDependencies + internalDependencies + externalDependencies + testingDependencies
)

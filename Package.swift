// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ApptentiveKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v11)
    ],
    products: [
        .library(
            name: "ApptentiveKit",
            targets: ["ApptentiveKit"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/iwill/generic-json-swift.git")
    ],
    targets: [
        .target(
            name: "ApptentiveKit",
            dependencies: [],
            exclude: ["Info.plist", "Bundle+Apptentive.swift"],
            resources: [.copy("Resources/SwiftPM.txt"), .copy("Resources/Distribution.plist")]
        ),
        .testTarget(
            name: "ApptentiveKit Tests",
            dependencies: ["GenericJSON"]),
        )
    ]
)

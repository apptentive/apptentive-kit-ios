// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ApptentiveKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "ApptentiveKit",
            targets: ["ApptentiveKit"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ApptentiveKit",
            dependencies: [],
            exclude: ["Info.plist", "Bundle+Apptentive.swift"]
        )
    ]
)

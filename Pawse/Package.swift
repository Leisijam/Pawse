// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Pawse",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Pawse",
            path: "Sources",
            resources: [
                .copy("Resources/DefaultCat.mov"),
                .copy("Resources/tab_day.png"),
                .copy("Resources/tab_night.png")
            ]
        )
    ]
)

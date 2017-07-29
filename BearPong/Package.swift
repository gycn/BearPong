// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BearPong",
    dependencies: [
        .Package(url: "https://github.com/socketio/socket.io-client-swift", majorVersion: 11)
    ]
)

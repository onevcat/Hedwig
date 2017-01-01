import PackageDescription

let package = Package(
    name: "Hedwig",
    dependencies: [
        .Package(url: "https://github.com/vapor/tls.git", majorVersion: 1),
        .Package(url: "https://github.com/vapor/crypto.git", majorVersion: 1),
        .Package(url: "https://github.com/onevcat/AddressParser.git", majorVersion: 1)
    ]
)

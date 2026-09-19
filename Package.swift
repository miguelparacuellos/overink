// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "Overink",
    platforms: [.macOS(.v15)],
    products: [
        .executable(name: "Overink", targets: ["OverinkApp"]),
    ],
    targets: [
        // Swift puro: el modelo y toda la lógica de decisión. No importa AppKit.
        // Vacío hasta que haya dominio que poner; el target de tests llega con él.
        .target(name: "OverinkCore"),
        // La shell de AppKit. Sin decisiones de dominio propias.
        .executableTarget(name: "OverinkApp", dependencies: ["OverinkCore"]),
    ]
)

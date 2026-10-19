// swift-tools-version: 6.2
import PackageDescription
let package = Package(
 name: "ReperaBusinessContracts",
 products: [.library(name: "ReperaBusinessContracts",targets: ["ReperaBusinessContracts"])],
 targets: [
  .target(name: "ReperaBusinessContracts"),
  .testTarget(name: "ReperaBusinessContractsTests",dependencies: ["ReperaBusinessContracts"])
 ]
)
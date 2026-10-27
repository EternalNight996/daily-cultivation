// swift-tools-version: 5.9
import PackageDescription

// 纯逻辑包：不依赖 UIKit / AVFoundation / Metal，因此在 macOS、Linux、Windows 上都能编译与测试。
// iOS App 通过 SPM 依赖它；画符判定、结算、日界这些"会算错就毁体验"的部分全在这里。
let package = Package(
    name: "TalismanKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "TalismanKit", targets: ["TalismanKit"])
    ],
    targets: [
        .target(name: "TalismanKit"),
        .testTarget(name: "TalismanKitTests", dependencies: ["TalismanKit"])
    ]
)

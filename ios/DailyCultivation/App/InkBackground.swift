import SwiftUI

/// 无相机时的兜底：不能是纯黑（会让 App 像坏了），要像"洞府里的暗室"。
struct InkBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [
                Color(red: 0.10, green: 0.11, blue: 0.13),
                Color(red: 0.05, green: 0.06, blue: 0.07)
            ], startPoint: .topLeading, endPoint: .bottomTrailing)

            RadialGradient(colors: [
                Color(red: 0.78, green: 0.64, blue: 0.36).opacity(0.10),
                .clear
            ], center: .init(x: 0.78, y: 0.12), startRadius: 8, endRadius: 420)

            RadialGradient(colors: [
                Color(red: 0.30, green: 0.55, blue: 0.52).opacity(0.08),
                .clear
            ], center: .init(x: 0.16, y: 0.86), startRadius: 8, endRadius: 380)
        }
    }
}

import SwiftUI

/// 冷灰水墨场景：优先用绘景资产（按四时辰切），没有资产时退回纯代码五层山。
struct InkBackground: View {
    var shichen: Shichen = .current()

    var body: some View {
        ZStack {
            if let ui = UIImage(named: "bg_\(shichen.rawValue)") {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                // 顶部一层极淡的白，保证标题与状态栏在任何一张绘景上都读得清
                LinearGradient(colors: [Color.white.opacity(0.30), .clear],
                               startPoint: .top,
                               endPoint: UnitPoint(x: 0.5, y: 0.30))
                    .ignoresSafeArea()
            } else {
                InkSceneVector()
            }
        }
        .ignoresSafeArea()
    }
}

/// 没有绘景资产时的兜底：纯代码五层山。
struct InkSceneVector: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [
                Color(red: 0.914, green: 0.933, blue: 0.937),
                Color(red: 0.827, green: 0.859, blue: 0.867),
                Color(red: 0.698, green: 0.753, blue: 0.765),
                Color(red: 0.561, green: 0.627, blue: 0.639),
                Color(red: 0.431, green: 0.490, blue: 0.506)
            ], startPoint: .top, endPoint: .bottom)

            RadialGradient(colors: [Color.white.opacity(0.85), Color.white.opacity(0.0)],
                           center: UnitPoint(x: 0.62, y: 0.12),
                           startRadius: 6, endRadius: 190)

            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height

                MountainShape(peaks: [
                    (0.00, 0.62), (0.13, 0.50), (0.24, 0.58), (0.38, 0.40),
                    (0.52, 0.58), (0.64, 0.46), (0.77, 0.59), (0.88, 0.49), (1.00, 0.58)
                ])
                .fill(LinearGradient(colors: [
                    Color(red: 0.545, green: 0.608, blue: 0.631).opacity(0.55),
                    Color(red: 0.416, green: 0.486, blue: 0.510).opacity(0.85)
                ], startPoint: .top, endPoint: .bottom))
                .frame(height: h * 0.50)
                .offset(y: h * 0.40)

                MountainShape(peaks: [
                    (0.00, 0.72), (0.12, 0.60), (0.26, 0.69), (0.40, 0.55),
                    (0.55, 0.70), (0.68, 0.60), (0.82, 0.72), (1.00, 0.62)
                ])
                .fill(LinearGradient(colors: [
                    Color(red: 0.369, green: 0.439, blue: 0.463).opacity(0.85),
                    Color(red: 0.271, green: 0.345, blue: 0.373).opacity(0.97)
                ], startPoint: .top, endPoint: .bottom))
                .frame(height: h * 0.44)
                .offset(y: h * 0.55)

                MountainShape(peaks: [
                    (0.00, 0.80), (0.15, 0.72), (0.33, 0.81), (0.50, 0.74),
                    (0.68, 0.82), (0.85, 0.75), (1.00, 0.80)
                ])
                .fill(Color(red: 0.106, green: 0.149, blue: 0.173).opacity(0.92))
                .frame(height: h * 0.26)
                .offset(y: h * 0.74)

                mist(width: w * 1.4, height: 120).offset(x: -w * 0.2, y: h * 0.44)
                mist(width: w * 1.5, height: 100).offset(x: w * 0.05, y: h * 0.62).opacity(0.75)
            }

            LinearGradient(colors: [.clear, .black.opacity(0.18)],
                           startPoint: .center, endPoint: .bottom)
        }
        .ignoresSafeArea()
    }

    private func mist(width: CGFloat, height: CGFloat) -> some View {
        Ellipse()
            .fill(Color.white.opacity(0.55))
            .frame(width: width, height: height)
            .blur(radius: 26)
    }
}

struct MountainShape: Shape {
    let peaks: [(CGFloat, CGFloat)]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard let first = peaks.first else { return path }
        path.move(to: CGPoint(x: first.0 * rect.width, y: first.1 * rect.height))
        for point in peaks.dropFirst() {
            path.addLine(to: CGPoint(x: point.0 * rect.width, y: point.1 * rect.height))
        }
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}

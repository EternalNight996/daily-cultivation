import SwiftUI

/// 阿团：灵胎化形的小兽。
/// V1 用矢量剪影——不做卡通大头，走"卧着的灵兽"轮廓：尖耳、长尾、杏仁眼。
struct PetView: View {
    let gaze: CGSize
    let celebrating: Bool

    @State private var breathing = false

    private let cream = Color(red: 0.949, green: 0.910, blue: 0.835)
    private let rim = Color(red: 0.62, green: 0.52, blue: 0.36)

    var body: some View {
        ZStack {
            // 地面阴影
            Ellipse()
                .fill(Color.black.opacity(0.18))
                .frame(width: 48, height: 7)
                .offset(y: 30)
                .blur(radius: 2)

            // 尾巴
            TailShape()
                .fill(bodyGradient)
                .frame(width: 34, height: 40)
                .offset(x: 26, y: 12)
                .rotationEffect(.degrees(breathing ? 4 : -2), anchor: .bottomLeading)

            // 身体 + 头 + 耳，一体剪影
            PetSilhouette()
                .fill(bodyGradient)
                .frame(width: 76, height: 74)
                .overlay(
                    PetSilhouette()
                        .stroke(rim.opacity(0.35), lineWidth: 0.6)
                        .frame(width: 76, height: 74)
                )

            // 眼睛
            eye.offset(x: -9 + gaze.width, y: -1 + gaze.height)
            eye.offset(x: 9 + gaze.width, y: -1 + gaze.height)

            // 鼻尖
            Circle()
                .fill(rim.opacity(0.55))
                .frame(width: 2.2, height: 2.2)
                .offset(y: 7)
        }
        .frame(width: 96, height: 96)
        .scaleEffect(breathing ? 1.02 : 0.985, anchor: .bottom)
        .offset(y: celebrating ? -8 : 0)
        .animation(.spring(response: 0.45, dampingFraction: 0.6), value: celebrating)
        .onAppear {
            withAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true)) {
                breathing = true
            }
        }
    }

    private var bodyGradient: LinearGradient {
        LinearGradient(colors: [
            Color(red: 0.173, green: 0.208, blue: 0.224),
            Color(red: 0.055, green: 0.078, blue: 0.094)
        ], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var eye: some View {
        Ellipse()
            .fill(cream)
            .frame(width: 4.6, height: 6.4)
            .rotationEffect(.degrees(-8))
    }
}

/// 头 + 身 + 双耳
struct PetSilhouette: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let cx = rect.midX
        let top = rect.minY

        // 双耳（细长、略外斜）
        p.move(to: CGPoint(x: cx - 13, y: top + 22))
        p.addLine(to: CGPoint(x: cx - 21, y: top + 2))
        p.addLine(to: CGPoint(x: cx - 4, y: top + 18))
        p.closeSubpath()

        p.move(to: CGPoint(x: cx + 13, y: top + 22))
        p.addLine(to: CGPoint(x: cx + 21, y: top + 2))
        p.addLine(to: CGPoint(x: cx + 4, y: top + 18))
        p.closeSubpath()

        // 头
        p.addEllipse(in: CGRect(x: cx - 17, y: top + 16, width: 34, height: 30))
        // 身（卧姿，压扁一点）
        p.addEllipse(in: CGRect(x: cx - 25, y: top + 34, width: 50, height: 38))

        return p
    }
}

/// 尾巴：从右侧卷起的一道弧
struct TailShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX + 2, y: rect.maxY))
        p.addCurve(to: CGPoint(x: rect.maxX - 2, y: rect.minY + 6),
                   control1: CGPoint(x: rect.maxX + 4, y: rect.maxY - 4),
                   control2: CGPoint(x: rect.maxX - 2, y: rect.minY + 22))
        p.addCurve(to: CGPoint(x: rect.minX + 10, y: rect.maxY - 4),
                   control1: CGPoint(x: rect.maxX - 14, y: rect.minY + 10),
                   control2: CGPoint(x: rect.minX + 16, y: rect.maxY - 22))
        p.closeSubpath()
        return p
    }
}

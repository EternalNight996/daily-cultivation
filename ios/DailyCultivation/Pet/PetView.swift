import SwiftUI

/// 阿团：灵胎化形的小兽。V1 只有三个状态——待机、施法跟随（眼睛追指尖）、经验共鸣。
/// 用矢量画而不是序列帧：美术资源到位前，先让"它在看我"这件事成立。
struct PetView: View {
    let gaze: CGSize              // -1…1 的归一化偏移
    let celebrating: Bool

    @State private var breathing = false

    private let bodyColor = Color(red: 0.10, green: 0.13, blue: 0.16)
    private let gold = Color(red: 0.79, green: 0.64, blue: 0.36)
    private let eyeColor = Color(red: 0.94, green: 0.89, blue: 0.77)

    var body: some View {
        ZStack {
            Ellipse()
                .fill(gold.opacity(0.12))
                .frame(width: 60, height: 9)
                .offset(y: 40)

            ear(flip: false).offset(x: -22, y: -28)
            ear(flip: true).offset(x: 22, y: -28)

            Ellipse()
                .fill(bodyColor)
                .overlay(Ellipse().stroke(gold.opacity(0.40), lineWidth: 1))
                .frame(width: 72, height: 66)

            eye.offset(x: -13 + gaze.width, y: -2 + gaze.height)
            eye.offset(x: 13 + gaze.width, y: -2 + gaze.height)
        }
        .frame(width: 96, height: 96)
        .scaleEffect(breathing ? 1.03 : 0.97, anchor: .bottom)
        .offset(y: celebrating ? -10 : 0)
        .animation(.spring(response: 0.45, dampingFraction: 0.6), value: celebrating)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                breathing = true
            }
        }
    }

    private var eye: some View {
        Circle()
            .fill(eyeColor)
            .frame(width: 7, height: 7)
    }

    private func ear(flip: Bool) -> some View {
        EarShape(flip: flip)
            .fill(bodyColor)
            .overlay(EarShape(flip: flip).stroke(gold.opacity(0.40), lineWidth: 1))
            .frame(width: 34, height: 38)
    }
}

private struct EarShape: Shape {
    let flip: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: flip ? rect.maxX : rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: flip ? rect.minX : rect.maxX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

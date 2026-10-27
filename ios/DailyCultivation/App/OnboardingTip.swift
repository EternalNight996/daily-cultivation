import SwiftUI

/// 首次施法引导。只在总施法数 < 3 时出现，不做永久教学。
struct OnboardingTip: View {
    let casts: Int
    let visible: Bool

    @State private var pulse = false

    var body: some View {
        if visible && casts < 3 {
            Text(copy)
                .font(.system(size: 12.5))
                .tracking(1.2)
                .foregroundStyle(.white.opacity(pulse ? 0.6 : 0.32))
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(.ultraThinMaterial, in: Capsule())
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                        pulse = true
                    }
                }
                .transition(.opacity)
        }
    }

    private var copy: String {
        switch casts {
        case 0: return "按住符头的光点，沿虚线画完三笔"
        case 1: return "慢慢画，画歪了只重画这一笔"
        default: return "符成之后，明日再来"
        }
    }
}

import SwiftUI
import TalismanKit

struct SettlementView: View {
    let settlement: QiBreakdown
    let streakDays: Int
    let onAgain: () -> Void

    private let gold = Color(red: 0.79, green: 0.64, blue: 0.36)
    private let jade = Color(red: 0.44, green: 0.75, blue: 0.69)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("符成 · 灵气入体")
                .font(.system(size: 11))
                .tracking(3)
                .foregroundStyle(.white.opacity(0.42))

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(settlement.total)")
                    .font(.system(size: 52, weight: .light))
                    .monospacedDigit()
                    .foregroundStyle(gold)
                Text("灵气")
                    .font(.system(size: 12))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(.top, 10)
            .padding(.bottom, 18)

            VStack(spacing: 9) {
                row("基础灵气", "\(settlement.base)")
                row(Shichen.current().label, "×\(String(format: "%.2f", settlement.shichenMultiplier))", highlighted: settlement.shichenMultiplier > 1)
                if settlement.streakBonus > 0 {
                    row("连续 \(streakDays) 天", "+\(Int(settlement.streakBonus * 100))%", highlighted: true)
                }
                if settlement.firstOfDayMultiplier > 1 {
                    row("今日首符", "×1.50", highlighted: true)
                }
                if settlement.petMultiplier > 1 {
                    row("阿团共鸣", "+10%", highlighted: true)
                }
                if settlement.capFactor < 1 {
                    row("灵气渐满", "×\(String(format: "%.2f", settlement.capFactor))")
                }
            }
            .padding(.bottom, 20)

            Button(action: onAgain) {
                Text("再画一道")
                    .font(.system(size: 14))
                    .tracking(1.5)
                    .foregroundStyle(gold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(gold.opacity(0.10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(gold.opacity(0.45), lineWidth: 1)
                            )
                    )
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 22)
        .padding(.bottom, 34)
        .background(
            LinearGradient(colors: [
                Color.black.opacity(0.55),
                Color.black.opacity(0.94),
                Color.black.opacity(0.99)
            ], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea(edges: .bottom)
        )
    }

    private func row(_ title: String, _ value: String, highlighted: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.62))
            Spacer()
            Text(value)
                .font(.system(size: 13))
                .monospacedDigit()
                .foregroundStyle(highlighted ? jade : .white.opacity(0.9))
        }
    }
}

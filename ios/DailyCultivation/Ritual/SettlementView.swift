import SwiftUI
import TalismanKit

struct SettlementView: View {
    let settlement: QiBreakdown
    let streakDays: Int
    let onAgain: () -> Void
    let onShare: () -> Void

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

            HStack(spacing: 10) {
                Button(action: onShare) {
                    Text("留个念")
                        .font(.system(size: 14))
                        .tracking(1.5)
                        .foregroundStyle(.white.opacity(0.62))
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.white.opacity(0.18), lineWidth: 1)
                        )
                }

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

// MARK: - 分享符画

/// 一张 900×1200 的竖版符画：宣纸底 + 符 + 灵气 + 朱砂印。
struct ShareCard: View {
    let qi: Int
    let streak: Int
    let talisman: Talisman
    let date: Date

    private let ink = Color(red: 0.086, green: 0.125, blue: 0.145)
    private let cinnabar = Color(red: 0.557, green: 0.184, blue: 0.133)

    private let cardSize = CGSize(width: 900, height: 1200)

    var body: some View {
        ZStack {
            Group {
                if UIImage(named: "paper_new") != nil {
                    Image("paper_new").resizable().scaledToFill()
                } else {
                    Color(red: 0.93, green: 0.89, blue: 0.80)
                }
            }
            .frame(width: cardSize.width, height: cardSize.height)
            .clipped()

            VStack(spacing: 0) {
                Text("每日修仙")
                    .font(.custom("Songti SC", size: 40))
                    .tracking(16)
                    .foregroundStyle(ink.opacity(0.85))

                Text(date, format: .dateTime.year().month().day().hour().minute())
                    .font(.system(size: 16))
                    .tracking(3)
                    .foregroundStyle(ink.opacity(0.45))
                    .padding(.top, 10)

                Spacer(minLength: 0)

                TalismanGlyph(strokes: talisman.strokes)
                    .frame(width: 380, height: 380)

                Spacer(minLength: 0)

                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("今日灵气")
                            .font(.system(size: 14))
                            .tracking(3)
                            .foregroundStyle(ink.opacity(0.45))
                        Text("+\(qi)")
                            .font(.system(size: 54, weight: .light))
                            .monospacedDigit()
                            .foregroundStyle(cinnabar)
                        Text("连续 \(streak) 天")
                            .font(.system(size: 13))
                            .tracking(2)
                            .foregroundStyle(ink.opacity(0.4))
                    }
                    Spacer()
                    if UIImage(named: "seal_chi") != nil {
                        Image("seal_chi")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 96, height: 96)
                    } else {
                        Text("敕")
                            .font(.custom("Songti SC", size: 26))
                            .foregroundStyle(.white)
                            .frame(width: 76, height: 76)
                            .background(RoundedRectangle(cornerRadius: 4).fill(cinnabar))
                    }
                }
            }
            .padding(.horizontal, 64)
            .padding(.vertical, 72)
            .frame(width: cardSize.width, height: cardSize.height)
        }
        .frame(width: cardSize.width, height: cardSize.height)
    }
}

/// 把符的归一化坐标画成矢量墨线
struct TalismanGlyph: View {
    let strokes: [[Vec2]]

    var body: some View {
        GeometryReader { geo in
            Path { path in
                for stroke in strokes {
                    for (index, point) in stroke.enumerated() {
                        let p = CGPoint(x: point.x * geo.size.width, y: point.y * geo.size.height)
                        if index == 0 { path.move(to: p) } else { path.addLine(to: p) }
                    }
                }
            }
            .stroke(Color(red: 0.086, green: 0.125, blue: 0.145).opacity(0.85),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
        }
    }
}

struct ShareCardSheet: View {
    let qi: Int
    let streak: Int
    let talisman: Talisman

    @Environment(\.dismiss) private var dismiss
    @State private var imageURL: URL?

    private let cinnabar = Color(red: 0.557, green: 0.184, blue: 0.133)

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                if let imageURL, let ui = UIImage(contentsOfFile: imageURL.path) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 24)

                    ShareLink(item: imageURL) {
                        Text("分享符画")
                            .font(.system(size: 15))
                            .tracking(2)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(RoundedRectangle(cornerRadius: 14).fill(cinnabar))
                    }
                    .padding(.horizontal, 24)
                } else {
                    ProgressView("正在写符…")
                        .tint(cinnabar)
                }
            }
            .navigationTitle("符画")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
            .task { render() }
        }
    }

    @MainActor
    private func render() {
        guard imageURL == nil else { return }
        let content = ShareCard(qi: qi, streak: streak, talisman: talisman, date: .now)
        let renderer = ImageRenderer(content: content)
        renderer.scale = 2
        guard let image = renderer.uiImage, let data = image.pngData() else { return }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("daily-cultivation-\(Int(Date.now.timeIntervalSince1970)).png")
        try? data.write(to: url)
        imageURL = url
    }
}

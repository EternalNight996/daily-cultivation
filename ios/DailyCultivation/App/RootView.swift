import SwiftUI
import TalismanKit

struct RootView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.scenePhase) private var scenePhase

    private let ink = Color(red: 0.086, green: 0.125, blue: 0.145)
    private let cinnabar = Color(red: 0.557, green: 0.184, blue: 0.133)
    private let paper = Color(red: 0.957, green: 0.910, blue: 0.843)

    @AppStorage("dc.sound") private var soundOn = true
    @AppStorage("dc.haptics") private var hapticsOn = true
    @AppStorage("dc.judge") private var judgeLevel = 1
    @AppStorage("dc.onboarded") private var onboarded = false
    @State private var activeSheet: ActiveSheet?

    private enum ActiveSheet: String, Identifiable {
        case settings, history, share
        var id: String { rawValue }
    }

    var body: some View {
        ZStack(alignment: .top) {
            if model.cameraEnabled && model.permission == .authorized && !model.inkOnly {
                CameraPreview(renderer: model.renderer)
                    .ignoresSafeArea()
                Color.black.opacity(0.10).ignoresSafeArea().allowsHitTesting(false)
            }

            if model.permission == .authorized || model.inkOnly {
                GeometryReader { geo in
                    RadialGradient(colors: [Color.white.opacity(0.55), Color.white.opacity(0.0)],
                                   center: .center, startRadius: 24, endRadius: 210)
                        .frame(width: geo.size.width * 1.15, height: geo.size.width * 1.15)
                        .position(x: geo.size.width / 2, y: geo.size.height * 0.47)
                        .blur(radius: 22)
                        .allowsHitTesting(false)
                }
                .ignoresSafeArea()

                TalismanCanvas(session: model.ritual,
                               strokeIndex: model.ritual.strokeIndex,
                               phase: model.ritual.phase)
                    .ignoresSafeArea()
            }

            header

            pet

            cameraControls

            if model.permission != .authorized && !model.inkOnly {
                PermissionView()
                    .transition(.opacity)
            }

            if let settlement = model.ritual.settlement {
                VStack(spacing: 0) {
                    Spacer()
                    SettlementView(settlement: settlement,
                                   streakDays: model.ritual.streakDays,
                                   onAgain: { model.ritual.reset() },
                                   onShare: { activeSheet = .share })
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(20)
            }

            if model.ritual.phase == .resting && model.ritual.settlement == nil {
                restingCard
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(21)
            }

            if let upgrade = model.ritual.titleUpgrade {
                TitleUpgradeView(title: upgrade,
                                 streak: model.ritual.snapshot.streak,
                                 autoDismiss: !previewHoldsUpgrade) {
                    model.ritual.dismissTitleUpgrade()
                }
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
                .zIndex(26)
            }

            if shouldShowOnboarding {
                OnboardingView { onboarded = true }
                    .transition(.opacity)
                    .zIndex(30)
            }
        }
        .background { InkBackground(shichen: model.shichen) }
        .animation(.easeInOut(duration: 0.35), value: model.permission)
        .animation(.easeInOut(duration: 0.35), value: model.cameraEnabled)
        .animation(.spring(response: 0.42, dampingFraction: 0.86), value: model.ritual.settlement)
        .task {
            Haptics.shared.prepare()
            model.bootstrap()
            applyPreviewStateIfNeeded()
        }
        .onChange(of: scenePhase) { _, phase in model.handleScenePhase(phase) }
        .onAppear {
            AudioPool.shared.setEnabled(soundOn)
            Haptics.isEnabled = hapticsOn
            model.applyJudgeLevel(judgeLevel)
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .settings:
                SettingsView()
                    .presentationDetents([.medium, .large])
            case .history:
                NavigationStack { HistoryView() }
            case .share:
                ShareCardSheet(qi: model.ritual.settlement?.total ?? 128,
                               streak: model.ritual.streakDays,
                               talisman: model.ritual.talisman)
            }
        }
    }

    // MARK: - 顶部

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 10) {
                    Text("每")
                        .font(.custom("Songti SC", size: 15))
                        .foregroundStyle(paper)
                        .frame(width: 26, height: 26)
                        .background(RoundedRectangle(cornerRadius: 3).fill(cinnabar))

                    VStack(alignment: .leading, spacing: 3) {
                        Text("每日修仙")
                            .font(.custom("Songti SC", size: 20))
                            .tracking(6)
                            .foregroundStyle(ink.opacity(0.9))
                        Text("第 \(model.ritual.snapshot.streak) 日 · \(model.ritual.snapshot.title.rawValue)")
                            .font(.system(size: 10))
                            .tracking(2)
                            .foregroundStyle(ink.opacity(0.45))
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 9) {
                HStack(spacing: 6) {
                    Circle().fill(cinnabar).frame(width: 6, height: 6)
                    Text(model.shichen.label)
                        .font(.system(size: 11))
                        .tracking(0.6)
                        .foregroundStyle(ink.opacity(0.72))
                    Text("×\(String(format: "%.1f", model.shichen.multiplier))")
                        .font(.system(size: 11))
                        .foregroundStyle(cinnabar)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().stroke(ink.opacity(0.12), lineWidth: 1))

                VStack(alignment: .trailing, spacing: 5) {
                    HStack(spacing: 2) {
                        Text("今日灵气")
                            .font(.system(size: 10))
                            .tracking(1.4)
                            .foregroundStyle(ink.opacity(0.45))
                        Text("\(model.ritual.snapshot.earnedToday)")
                            .font(.system(size: 13, weight: .medium))
                            .monospacedDigit()
                            .foregroundStyle(cinnabar)
                        Text("/ 600")
                            .font(.system(size: 10))
                            .foregroundStyle(ink.opacity(0.38))
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(ink.opacity(0.12))
                            Capsule()
                                .fill(cinnabar.opacity(0.7))
                                .frame(width: geo.size.width * min(1, Double(model.ritual.snapshot.earnedToday) / 600))
                        }
                    }
                    .frame(width: 104, height: 2)

                    Text("\(model.ritual.talisman.name) · \(model.ritual.talisman.strokes.count) 笔")
                        .font(.custom("Songti SC", size: 10))
                        .tracking(2)
                        .foregroundStyle(ink.opacity(0.4))
                }
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 8)
    }

    // MARK: - 宠物

    private var pet: some View {
        VStack {
            Spacer()
            HStack {
                PetView(state: petState,
                        gaze: model.ritual.gaze,
                        celebrating: model.ritual.phase == .settling)
                    .frame(width: 84, height: 84)
                    .offset(y: model.ritual.phase == .settling ? -170 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.72), value: model.ritual.phase)
                    .padding(.leading, 18)
                Spacer()
            }
            .padding(.bottom, 150)
        }
        .allowsHitTesting(false)
    }

    private var petState: PetView.Mood {
        if model.ritual.phase == .settling { return .resonate }
        if model.ritual.lastScore != nil { return .cast }
        return .idle
    }

    /// 截图模式下让升级弹层停住，否则 3 秒后自动消失，截不到
    private var previewHoldsUpgrade: Bool {
#if DEBUG
        return model.previewState == "upgrade"
#else
        return false
#endif
    }

    private var shouldShowOnboarding: Bool {
#if DEBUG
        // 截图模式下只有 onboarding 这一态显示引导，其余状态一律当它已经看过
        if let state = model.previewState { return state == "onboarding" }
#endif
        return !onboarded
    }

    private func applyPreviewStateIfNeeded() {
#if DEBUG
        switch model.previewState {
        case "resting":
            model.ritual.forceRestingForPreview()
        case "history":
            model.seedPreviewRecords()
            activeSheet = .history
        case "share":
            activeSheet = .share
        case "settings":
            activeSheet = .settings
        case "idle":
            break
        case "upgrade":
            model.ritual.forceTitleUpgradeForPreview()
        case "settle":
            model.ritual.forceSettleForPreview()
        default:
            break
        }
#endif
    }

    // MARK: - 今日圆满

    private var restingCard: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 16) {
                Text("今日已圆满")
                    .font(.custom("Songti SC", size: 24))
                    .tracking(8)
                    .foregroundStyle(ink.opacity(0.9))

                Text("三道符已画完，明日 04:00 再会")
                    .font(.system(size: 12))
                    .tracking(1.5)
                    .foregroundStyle(ink.opacity(0.5))

                TimelineView(.periodic(from: .now, by: 1)) { _ in
                    Text(timeUntilReset())
                        .font(.system(size: 30, weight: .light))
                        .monospacedDigit()
                        .foregroundStyle(cinnabar.opacity(0.85))
                }

                HStack(spacing: 12) {
                    Button("看修行录") { activeSheet = .history }
                        .font(.system(size: 13))
                        .foregroundStyle(cinnabar)
                    Text("·").foregroundStyle(ink.opacity(0.2))
                    Text("明早 04:00 见")
                        .font(.system(size: 13))
                        .foregroundStyle(ink.opacity(0.45))
                }
                .padding(.top, 4)
            }
            .padding(.vertical, 26)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(ink.opacity(0.12), lineWidth: 1))
            .padding(.horizontal, 22)
            .padding(.bottom, 44)
        }
    }

    /// 修炼日以 04:00 为界，倒计时到下一个 04:00
    private func timeUntilReset(now: Date = .now) -> String {
        let cal = Calendar.current
        let today4 = cal.date(bySettingHour: 4, minute: 0, second: 0, of: now) ?? now
        let next = now < today4 ? today4 : (cal.date(byAdding: .day, value: 1, to: today4) ?? today4)
        let seconds = max(0, Int(next.timeIntervalSince(now)))
        return String(format: "%02d:%02d:%02d", seconds / 3600, (seconds % 3600) / 60, seconds % 60)
    }

    // MARK: - 灵镜

    private var cameraControls: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack(spacing: 10) {
                    circleButton(model.cameraEnabled ? "收镜" : "灵镜", primary: true) {
                        model.toggleCamera()
                    }
                    if model.cameraEnabled {
                        circleButton("翻转", primary: false) { model.flipCamera() }
                        circleButton("留影", primary: false) { model.capturePhoto() }
                    }
                    circleButton("示范", primary: false) { model.drawDemoStroke() }
                    circleButton("设置", primary: false) { activeSheet = .settings }
                }
                .padding(.trailing, 18)
                .padding(.bottom, 96)
            }
        }
    }

    private func circleButton(_ title: String, primary: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.custom("Songti SC", size: primary ? 11 : 10))
                .tracking(1)
                .foregroundStyle(ink.opacity(primary ? 0.82 : 0.7))
                .frame(width: primary ? 54 : 42, height: primary ? 54 : 42)
                .background(Circle().fill(Color.white.opacity(primary ? 0.42 : 0.34)))
                .overlay(Circle().stroke(ink.opacity(0.22), lineWidth: 1))
        }
    }
}

// MARK: - 设置

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @AppStorage("dc.sound") private var soundOn = true
    @AppStorage("dc.haptics") private var hapticsOn = true
    @AppStorage("dc.judge") private var judgeLevel = 1
    @AppStorage("dc.inkCamera") private var inkCamera = true
    @AppStorage("dc.onboarded") private var onboarded = false
    @State private var confirmReset = false
    @State private var confirmResetAll = false

    private let ink = Color(red: 0.086, green: 0.125, blue: 0.145)
    private let cinnabar = Color(red: 0.557, green: 0.184, blue: 0.133)
    private let paper = Color(red: 0.957, green: 0.910, blue: 0.843)

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("音效", isOn: $soundOn)
                    Toggle("触感", isOn: $hapticsOn)
                    Toggle("相机水墨调色", isOn: $inkCamera)
                } header: {
                    Text("手感")
                } footer: {
                    Text("关掉音效与触感后画符仍可判定。相机调色关掉会回到原色画面。")
                }

                Section {
                    Picker("判定", selection: $judgeLevel) {
                        Text("宽松").tag(0)
                        Text("标准").tag(1)
                        Text("严格").tag(2)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("判定")
                } footer: {
                    Text("宽松适合第一次玩；严格会更看重笔形与收笔位置。")
                }

                Section {
                    NavigationLink("修行录") { HistoryView() }
                } header: {
                    Text("修行")
                }

                Section("数据") {
                    Button("重置今日修行", role: .destructive) { confirmReset = true }
                    Button("重置全部（含引导）", role: .destructive) { confirmResetAll = true }
                    LabeledContent("连续天数", value: "\(model.ritual.snapshot.streak) 天")
                    LabeledContent("今日灵气", value: "\(model.ritual.snapshot.earnedToday)")
                }

                Section {
                    LabeledContent("版本", value: "1.0.0 (1)")
                    LabeledContent("数据", value: "仅存本机")
                    Text("V1 不联网、不上传、无账号。修行记录只保存在这台设备上。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("关于")
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
            .onChange(of: soundOn) { _, value in AudioPool.shared.setEnabled(value) }
            .onChange(of: hapticsOn) { _, value in Haptics.isEnabled = value }
            .onChange(of: judgeLevel) { _, value in model.applyJudgeLevel(value) }
            .onChange(of: inkCamera) { _, value in model.applyInkCamera(value) }
            .confirmationDialog("重置今日记录？", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("重置", role: .destructive) { model.resetToday() }
                Button("取消", role: .cancel) {}
            } message: {
                Text("只清空今天的灵气与笔数，连续天数保留。")
            }
            .confirmationDialog("重置全部数据？", isPresented: $confirmResetAll, titleVisibility: .visible) {
                Button("全部重置", role: .destructive) {
                    model.resetToday()
                    onboarded = false
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("清空所有修行记录与引导状态，下次打开会重新引导。")
            }
        }
        .tint(cinnabar)
    }
}


// MARK: - 修行录

struct HistoryView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    private let ink = Color(red: 0.086, green: 0.125, blue: 0.145)
    private let cinnabar = Color(red: 0.557, green: 0.184, blue: 0.133)

    var body: some View {
        Group {
            if model.records.isEmpty {
                ContentUnavailableView(
                    "还没有记录",
                    systemImage: "square.and.pencil",
                    description: Text("画完第一道符，这里就会记下它。")
                )
            } else {
                List {
                    Section {
                        LabeledContent("累计施法", value: "\(model.ritual.snapshot.totalCasts) 次")
                        LabeledContent("连续修行", value: "\(model.ritual.snapshot.streak) 天")
                        LabeledContent("今日已施法", value: "\(model.ritual.snapshot.castsToday) 次")
                    }

                    Section("最近") {
                        ForEach(model.records) { record in
                            row(record)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("修行录")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("完成") { dismiss() }
            }
        }
        .task { model.loadRecords() }
        .tint(cinnabar)
    }

    private func row(_ record: CultivationStore.Record) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(record.date, format: .dateTime.month().day().hour().minute())
                    .font(.system(size: 14))
                    .foregroundStyle(ink.opacity(0.85))
                Text(record.shichen.label)
                    .font(.system(size: 11))
                    .foregroundStyle(ink.opacity(0.4))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text("+\(record.qi)")
                    .font(.system(size: 14, weight: .medium))
                    .monospacedDigit()
                    .foregroundStyle(cinnabar)
                Text(String(format: "%.0f%%", record.score * 100))
                    .font(.system(size: 11))
                    .monospacedDigit()
                    .foregroundStyle(ink.opacity(0.4))
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - 首次引导

/// 第一次打开时教三件事：怎么起笔、几笔成符、一天几次。
struct OnboardingView: View {
    let onFinish: () -> Void

    @State private var step = 0

    private let ink = Color(red: 0.086, green: 0.125, blue: 0.145)
    private let cinnabar = Color(red: 0.557, green: 0.184, blue: 0.133)

    private let pages: [(title: String, body: String)] = [
        ("按住朱砂点", "从符头那颗红点起笔，顺着虚线走。偏一点也没关系，画得越贴，灵气越多。"),
        ("三笔成符", "每一笔都要走到收笔处。三笔画完，符成、落印、灵气入体。"),
        ("每日三符", "子时 ×1.6、午时 ×1.5，卯酉 ×1.3。画满三道就是圆满，明日 04:00 再来。")
    ]

    var body: some View {
        ZStack {
            Color.black.opacity(0.26).ignoresSafeArea()

            VStack {
                Spacer()

                VStack(spacing: 18) {
                    Text(pages[step].title)
                        .font(.custom("Songti SC", size: 24))
                        .tracking(8)
                        .foregroundStyle(ink.opacity(0.9))

                    Text(pages[step].body)
                        .font(.system(size: 13))
                        .lineSpacing(7)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(ink.opacity(0.55))
                        .padding(.horizontal, 8)

                    HStack(spacing: 6) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Circle()
                                .fill(index == step ? cinnabar : ink.opacity(0.16))
                                .frame(width: 5, height: 5)
                        }
                    }
                    .padding(.top, 2)

                    Button {
                        if step < pages.count - 1 {
                            withAnimation(.easeInOut(duration: 0.2)) { step += 1 }
                        } else {
                            onFinish()
                        }
                    } label: {
                        Text(step < pages.count - 1 ? "下一步" : "开始画符")
                            .font(.system(size: 14))
                            .tracking(2)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(RoundedRectangle(cornerRadius: 13).fill(cinnabar.opacity(0.92)))
                    }
                    .padding(.top, 6)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 26)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
                .overlay(
                    RoundedRectangle(cornerRadius: 24).stroke(ink.opacity(0.10), lineWidth: 1)
                )
                .padding(.horizontal, 22)
                .padding(.bottom, 86)
            }
        }
        .transition(.opacity)
    }
}

// MARK: - 境界提升

/// 跨过称号门槛时的那一下：一张纸、一个印、四个字。3 秒后自己走。
struct TitleUpgradeView: View {
    let title: Title
    let streak: Int
    var autoDismiss: Bool = true
    let onDismiss: () -> Void

    private let ink = Color(red: 0.086, green: 0.125, blue: 0.145)
    private let cinnabar = Color(red: 0.557, green: 0.184, blue: 0.133)

    var body: some View {
        ZStack {
            Color.black.opacity(0.22)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 16) {
                Text("境界提升")
                    .font(.system(size: 11))
                    .tracking(6)
                    .foregroundStyle(ink.opacity(0.45))

                Text(title.rawValue)
                    .font(.custom("Songti SC", size: 46))
                    .tracking(14)
                    .foregroundStyle(ink.opacity(0.9))

                Rectangle()
                    .fill(cinnabar.opacity(0.45))
                    .frame(width: 44, height: 1)

                Text("连续修行 \(streak) 天")
                    .font(.system(size: 12))
                    .tracking(2)
                    .foregroundStyle(ink.opacity(0.5))

                if UIImage(named: "seal_chi") != nil {
                    Image("seal_chi")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .padding(.top, 4)
                }
            }
            .padding(.horizontal, 48)
            .padding(.vertical, 34)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(cinnabar.opacity(0.28), lineWidth: 1)
            )
            .onTapGesture { onDismiss() }
        }
        .task {
            guard autoDismiss else { return }
            try? await Task.sleep(nanoseconds: 3_200_000_000)
            onDismiss()
        }
    }
}
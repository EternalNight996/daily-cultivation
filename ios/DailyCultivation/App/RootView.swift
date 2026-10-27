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
    @State private var showSettings = false

    var body: some View {
        ZStack(alignment: .top) {
            InkBackground(shichen: model.shichen)

            if model.cameraEnabled && model.permission == .authorized && !model.inkOnly {
                CameraPreview(renderer: model.renderer)
                    .ignoresSafeArea()
                Color.black.opacity(0.10).ignoresSafeArea().allowsHitTesting(false)
            }

            if model.permission == .authorized || model.inkOnly {
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
                                   onAgain: { model.ritual.reset() })
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(20)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: model.permission)
        .animation(.easeInOut(duration: 0.35), value: model.cameraEnabled)
        .animation(.spring(response: 0.42, dampingFraction: 0.86), value: model.ritual.settlement)
        .task {
            Haptics.shared.prepare()
            model.bootstrap()
        }
        .onChange(of: scenePhase) { _, phase in model.handleScenePhase(phase) }
        .onAppear {
            AudioPool.shared.setEnabled(soundOn)
            Haptics.isEnabled = hapticsOn
            model.applyJudgeLevel(judgeLevel)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .presentationDetents([.medium, .large])
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

    private var petState: PetView.State {
        if model.ritual.phase == .settling { return .resonate }
        if model.ritual.lastScore != nil { return .cast }
        return .idle
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
                    circleButton("设置", primary: false) { showSettings = true }
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
    @State private var confirmReset = false

    private let ink = Color(red: 0.086, green: 0.125, blue: 0.145)
    private let cinnabar = Color(red: 0.557, green: 0.184, blue: 0.133)
    private let paper = Color(red: 0.957, green: 0.910, blue: 0.843)

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("音效", isOn: $soundOn)
                    Toggle("触感", isOn: $hapticsOn)
                } header: {
                    Text("手感")
                } footer: {
                    Text("关掉后画符仍然可判，只是没有声音与震动。")
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

                Section("数据") {
                    Button("重置今日修行", role: .destructive) { confirmReset = true }
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
            .confirmationDialog("重置今日记录？", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("重置", role: .destructive) { model.resetToday() }
                Button("取消", role: .cancel) {}
            } message: {
                Text("只清空今天的灵气与笔数，连续天数保留。")
            }
        }
        .tint(cinnabar)
    }
}


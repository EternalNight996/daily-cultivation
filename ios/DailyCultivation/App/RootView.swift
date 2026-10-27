import SwiftUI
import TalismanKit

struct RootView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            InkBackground().ignoresSafeArea()

            if model.permission == .authorized && !model.inkOnly {
                CameraPreview(renderer: model.renderer)
                    .ignoresSafeArea()
                    .transition(.opacity)

                // 压暗四周，把视线收进画面中心；同时让白色 HUD 在任何实景上都能读
                RadialGradient(colors: [.clear, .black.opacity(0.55)],
                               center: .center, startRadius: 140, endRadius: 480)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            if model.permission == .authorized || model.inkOnly {
                TalismanCanvas(session: model.ritual,
                               strokeIndex: model.ritual.strokeIndex,
                               phase: model.ritual.phase)
                    .ignoresSafeArea()
            }

            VStack(spacing: 0) {
                HeaderBar(streak: model.ritual.snapshot.streak,
                          title: model.ritual.snapshot.title,
                          shichen: model.shichen)
                    .padding(.horizontal, 20)
                    .padding(.top, 6)
                Spacer()
            }

            if model.permission != .authorized && !model.inkOnly {
                PermissionView()
                    .transition(.opacity)
            }

            if model.permission == .authorized || model.inkOnly {
                VStack {
                    Spacer()
                    HStack {
                        PetView(gaze: model.ritual.gaze,
                                celebrating: model.ritual.phase == .settling)
                            .offset(y: model.ritual.phase == .settling ? -190 : 0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.72),
                                       value: model.ritual.phase)
                            .padding(.leading, 18)
                        Spacer()
                    }
                    .padding(.bottom, 150)
                }
                .allowsHitTesting(false)

                VStack {
                    Spacer()
                    OnboardingTip(casts: model.ritual.snapshot.totalCasts,
                                  visible: model.ritual.phase == .drawing)
                        .padding(.bottom, 210)
                }
                .allowsHitTesting(false)
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

            #if DEBUG
            VStack {
                Spacer()
                Text("V1 · 相机链路")
                    .font(.system(size: 10, weight: .medium))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.20))
                    .padding(.bottom, 10)
            }
            .allowsHitTesting(false)
            #endif
        }
        .animation(.easeInOut(duration: 0.5), value: model.permission)
        .animation(.spring(response: 0.42, dampingFraction: 0.86), value: model.ritual.settlement)
        .animation(.easeInOut(duration: 0.3), value: model.ritual.snapshot.totalCasts)
        .task {
            Haptics.shared.prepare()
            model.bootstrap()
        }
        .onChange(of: scenePhase) { _, phase in model.handleScenePhase(phase) }
    }
}

private struct HeaderBar: View {
    let streak: Int
    let title: Title
    let shichen: Shichen

    private let gold = Color(red: 0.79, green: 0.64, blue: 0.36)

    var body: some View {
        HStack(alignment: .center) {
            Text("连续 \(streak) 天 · \(title.rawValue)")
                .font(.system(size: 12))
                .tracking(1.4)
                .foregroundStyle(.white.opacity(0.62))

            Spacer()

            HStack(spacing: 7) {
                Circle()
                    .fill(gold)
                    .frame(width: 6, height: 6)
                Text(shichen.label)
                Text("×\(String(format: "%.1f", shichen.multiplier))")
                    .foregroundStyle(gold)
            }
            .font(.system(size: 12))
            .tracking(0.8)
            .foregroundStyle(.white.opacity(0.82))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(.ultraThinMaterial, in: Capsule())
        }
    }
}

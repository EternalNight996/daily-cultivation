import AVFoundation
import Foundation
import Observation
import SwiftUI

extension Notification.Name {
    /// 「示范」按钮：让画布自动画完当前一笔（模拟器上用鼠标画不准时的兜底）
    static let demoStroke = Notification.Name("dc.demoStroke")
}

@MainActor
@Observable
final class AppModel {
    var permission: CameraPermission = .notDetermined
    /// 用户拒绝/受限时仍可继续体验：退回水墨洞府，核心闭环不受影响
    var inkOnly = false
    /// 相机默认关闭：点「灵镜」才开采集，省电也省隐私顾虑
    var cameraEnabled = false
    /// 进前台时重算，HUD 与渲染共用
    var shichen: Shichen = .current()

    let camera: CameraSession
    let renderer: CameraRenderer
    let ritual = RitualSession()
    private let store: CultivationStore

    init() {
        let camera = CameraSession()
        self.camera = camera
        self.renderer = CameraRenderer(frames: camera.frames)

        let store = CultivationStore(container: PersistenceController.shared.container)
        self.store = store
        ritual.store = store
    }

    func bootstrap() {
        if AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) == nil {
            inkOnly = true
        }
        AudioPool.shared.prepare()
        shichen = Shichen.current()
        renderer.setShichen(shichen)
        ritual.refreshSnapshot()
        permission = .current
    }

    func requestCamera() async {
        if permission == .notDetermined {
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            permission = granted ? .authorized : .denied
        } else {
            permission = .current
        }
        if permission == .authorized { cameraEnabled = true; camera.start() }
    }

    func toggleCamera() {
        if cameraEnabled {
            cameraEnabled = false
            camera.stop()
            return
        }
        if permission == .authorized {
            cameraEnabled = true
            camera.start()
        } else {
            Task { await requestCamera() }
        }
    }

    func flipCamera() {
        camera.flip()
    }

    func capturePhoto() {
        camera.capturePhoto { data in
            AppLog.capture.info("photo captured: \(data?.count ?? 0) bytes")
        }
    }

    /// 判定三档：宽松 / 标准 / 严格
    func applyJudgeLevel(_ level: Int) {
        var config = MatchConfig()
        switch level {
        case 0:
            config.passThreshold = 0.66
            config.assistedThreshold = 0.58
            config.helpThreshold = 0.48
        case 2:
            config.passThreshold = 0.78
            config.assistedThreshold = 0.70
            config.helpThreshold = 0.60
        default:
            break
        }
        ritual.config = config
    }

    func resetToday() {
        store.resetForDebug()
        ritual.refreshSnapshot()
    }

    func drawDemoStroke() {
        NotificationCenter.default.post(name: .demoStroke, object: nil)
    }

    func refreshPermission() {
        permission = .current
    }

    func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .active:
            shichen = Shichen.current()
            renderer.setShichen(shichen)
            if cameraEnabled && permission == .authorized { camera.start() }
        case .inactive, .background:
            // 进后台一律停采集：省电，也避免"后台用相机"的隐私质疑
            camera.stop()
        @unknown default:
            break
        }
    }
}

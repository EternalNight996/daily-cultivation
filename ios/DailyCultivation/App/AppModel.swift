import AVFoundation
import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class AppModel {
    var permission: CameraPermission = .notDetermined
    /// 时辰在"进前台"时重算，HUD 与渲染共用它
    var shichen: Shichen = .current()
    /// 用户拒绝/受限时仍可继续体验：退回水墨洞府，核心闭环不受影响
    var inkOnly = false

    let camera: CameraSession
    let renderer: CameraRenderer
    let ritual = RitualSession()
    private let store: CultivationStore

    init() {
        // 不能写成 camera = CameraSession(); renderer = CameraRenderer(frames: camera.frames)
        // 那会在 renderer 初始化前就访问 self.camera
        let camera = CameraSession()
        self.camera = camera
        self.renderer = CameraRenderer(frames: camera.frames)

        let store = CultivationStore(container: PersistenceController.shared.container)
        self.store = store
        ritual.store = store
    }

    func bootstrap() {
        // 模拟器没有摄像头：直接进水墨兜底，否则会看到一块纯黑
        if AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) == nil {
            inkOnly = true
        }
        AudioPool.shared.prepare()
        shichen = Shichen.current()
        renderer.setShichen(shichen)
        ritual.refreshSnapshot()
        permission = .current
        // 已授权才启动采集；未决定时先展示解释页，绝不冷启动直接弹系统权限框
        if permission == .authorized { camera.start() }
    }

    func requestCamera() async {
        if permission == .notDetermined {
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            permission = granted ? .authorized : .denied
        } else {
            permission = .current
        }
        if permission == .authorized { camera.start() }
    }

    func refreshPermission() {
        permission = .current
        if permission == .authorized { camera.start() } else { camera.stop() }
    }

    func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .active:
            // 回到前台时重算时辰：跨过 23:00/05:00 这类边界后，配色要跟着换
            shichen = Shichen.current()
            renderer.setShichen(shichen)
            if permission == .authorized { camera.start() }
        case .inactive, .background:
            // 进后台立刻停采集：省电，也避免"后台用相机"的隐私质疑
            camera.stop()
        @unknown default:
            break
        }
    }
}

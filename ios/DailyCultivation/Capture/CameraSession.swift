import AVFoundation
import CoreImage
import Foundation

/// 摄像头采集。约定：
/// - 所有 session 变更都走 sessionQueue，startRunning/stopRunning 绝不上主线程（首次要 200–600ms）
/// - sampleBuffer 回调在 videoQueue，只做 CIImage 包装，不做任何图像处理
/// - 720p@30 是 V1 的基线；1080p 的热与带宽代价换不来多少观感
final class CameraSession: NSObject, @unchecked Sendable {
    let frames = FrameStore()

    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "dc.capture.session", qos: .userInitiated)
    private let videoQueue = DispatchQueue(label: "dc.capture.video", qos: .userInitiated)
    private let output = AVCaptureVideoDataOutput()
    private var isConfigured = false
    private var observers: [NSObjectProtocol] = []

    override init() {
        super.init()
        observeInterruptions()
    }

    deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    func start() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            do {
                if !self.isConfigured {
                    try self.configure()
                    self.isConfigured = true
                }
                if !self.session.isRunning { self.session.startRunning() }
            } catch {
                // 相机不可用不阻塞 App：渲染层会退回水墨背景
                AppLog.capture.error("camera start failed: \(String(describing: error), privacy: .public)")
            }
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.session.isRunning { self.session.stopRunning() }
        }
    }

    private func configure() throws {
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        session.sessionPreset = .hd1280x720

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        else { throw CameraError.noDevice }

        let input = try AVCaptureDeviceInput(device: device)
        guard session.canAddInput(input) else { throw CameraError.cannotAddInput }
        session.addInput(input)

        try device.lockForConfiguration()
        // 固定 30fps：避免自动曝光在 24–30 之间漂移导致亮度闪烁
        let fps = CMTime(value: 1, timescale: 30)
        if device.activeFormat.videoSupportedFrameRateRanges.contains(where: { $0.maxFrameRate >= 30 }) {
            device.activeVideoMinFrameDuration = fps
            device.activeVideoMaxFrameDuration = fps
        }
        device.unlockForConfiguration()

        output.alwaysDiscardsLateVideoFrames = true     // 只认最新帧
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
        ]
        output.setSampleBufferDelegate(self, queue: videoQueue)
        guard session.canAddOutput(output) else { throw CameraError.cannotAddOutput }
        session.addOutput(output)

        // 竖屏取景：采集侧不旋转（逐帧物理旋转有成本），在渲染层用 .oriented(.right)
        output.connection(with: .video)?.videoRotationAngle = 0
    }

    private func observeInterruptions() {
        let center = NotificationCenter.default
        let names: [Notification.Name] = [
            .AVCaptureSessionWasInterrupted,
            .AVCaptureSessionInterruptionEnded,
            .AVCaptureSessionRuntimeError
        ]
        observers = names.map { name in
            center.addObserver(forName: name, object: session, queue: nil) { [weak self] note in
                self?.handle(notification: note)
            }
        }
    }

    private func handle(notification: Notification) {
        switch notification.name {
        case .AVCaptureSessionWasInterrupted:
            // 被电话/其他 App 占用：保持在最后一帧，不要清空画面
            AppLog.capture.info("session interrupted")
        case .AVCaptureSessionInterruptionEnded:
            sessionQueue.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                guard let self, !self.session.isRunning else { return }
                self.session.startRunning()
            }
        case .AVCaptureSessionRuntimeError:
            AppLog.capture.error("session runtime error")
            start()
        default:
            break
        }
    }
}

enum CameraError: Error {
    case noDevice
    case cannotAddInput
    case cannotAddOutput
}

extension CameraSession: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        // 只包装，不做滤镜：滤镜在渲染线程的 CIContext 里做
        frames.publish(CIImage(cvPixelBuffer: buffer))
    }
}

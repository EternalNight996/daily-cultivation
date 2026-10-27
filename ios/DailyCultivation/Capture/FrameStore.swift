import CoreImage
import Foundation

/// 采集线程与渲染线程之间只交接"最新一帧"，不做队列。
/// 画符只认最新画面，积压只会增加延迟。
final class FrameStore: @unchecked Sendable {
    private let lock = NSLock()
    private var image: CIImage?
    private var generation: UInt64 = 0

    func publish(_ image: CIImage) {
        lock.lock()
        self.image = image
        generation &+= 1
        lock.unlock()
    }

    func latest() -> (image: CIImage, generation: UInt64)? {
        lock.lock()
        defer { lock.unlock() }
        guard let image else { return nil }
        return (image, generation)
    }
}

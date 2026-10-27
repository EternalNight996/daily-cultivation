import CoreImage
import Metal
import MetalKit
import OSLog

/// 相机滤镜渲染。关键约定：
/// - CIContext 走 Metal，渲染直接进 drawable 的 texture，绝不经过 CGImage（那会多两次拷贝）
/// - 先摆正、再 aspect fill、最后调色，顺序错了会得到拉伸或黑边
/// - draw 在主线程（MTKView 的默认行为），CI 内部异步走 GPU
final class CameraRenderer: NSObject, MTKViewDelegate, @unchecked Sendable {
    private let frames: FrameStore
    private let commandQueue: MTLCommandQueue?
    private let context: CIContext?
    private let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!

    /// 只允许在主线程改（draw 也在主线程），因此不需要加锁
    private var palette = RenderPalette.forShichen(.current())

    func setShichen(_ shichen: Shichen) {
        palette = RenderPalette.forShichen(shichen)
    }

    init(frames: FrameStore) {
        self.frames = frames
        let device = MTLCreateSystemDefaultDevice()
        self.commandQueue = device?.makeCommandQueue()
        self.context = device.map { device in
            CIContext(mtlDevice: device, options: [
                .workingColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
                .outputColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
                .cacheIntermediates: false
            ])
        }
        super.init()
        if context == nil {
            AppLog.render.error("Metal unavailable, falling back to ink background")
        }
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard let context, let commandQueue,
              let drawable = view.currentDrawable,
              let buffer = commandQueue.makeCommandBuffer(),
              let frame = frames.latest()
        else { return }

        let size = view.drawableSize
        guard size.width >= 1, size.height >= 1 else { return }

        let output = grade(frame.image, to: size)
        context.render(output,
                       to: drawable.texture,
                       commandBuffer: buffer,
                       bounds: CGRect(origin: .zero, size: size),
                       colorSpace: colorSpace)
        buffer.present(drawable)
        buffer.commit()
    }

    private func grade(_ image: CIImage, to size: CGSize) -> CIImage {
        // 1) 摆正：采集侧不旋转，这里用元数据变换，不额外消耗一次 pass
        let oriented = image.oriented(.right)

        // 2) aspect fill：铺满 drawable，多出来的部分裁掉
        let extent = oriented.extent
        guard extent.width > 0, extent.height > 0 else { return image }
        let scale = max(size.width / extent.width, size.height / extent.height)
        let scaled = oriented.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let dx = (size.width - scaled.extent.width) / 2 - scaled.extent.origin.x
        let dy = (size.height - scaled.extent.height) / 2 - scaled.extent.origin.y
        let filled = scaled.transformed(by: CGAffineTransform(translationX: dx, y: dy))

        // 3) 调色：色温/饱和/辉光/暗角由时辰驱动
        let graded = filled
            .applyingFilter("CIColorControls", parameters: [
                kCIInputSaturationKey: palette.saturation,
                kCIInputContrastKey: palette.contrast,
                kCIInputBrightnessKey: -0.01
            ])
            .applyingFilter("CITemperatureAndTint", parameters: [
                "inputNeutral": CIVector(x: 6500, y: 0),
                "inputTargetNeutral": CIVector(x: palette.targetNeutral, y: 0)
            ])
            .applyingFilter("CIBloom", parameters: [
                kCIInputRadiusKey: palette.bloomRadius,
                kCIInputIntensityKey: palette.bloomIntensity
            ])
            .applyingFilter("CIVignette", parameters: [
                kCIInputIntensityKey: palette.vignetteIntensity,
                kCIInputRadiusKey: 1.80
            ])

        return graded.cropped(to: CGRect(origin: .zero, size: size))
    }
}

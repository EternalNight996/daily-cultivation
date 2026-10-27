import Metal
import MetalKit
import SwiftUI

struct CameraPreview: UIViewRepresentable {
    let renderer: CameraRenderer

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView(frame: .zero, device: MTLCreateSystemDefaultDevice())
        view.framebufferOnly = true
        view.colorPixelFormat = .bgra8Unorm
        view.preferredFramesPerSecond = 60
        view.enableSetNeedsDisplay = false
        view.isPaused = false
        view.delegate = renderer
        view.isOpaque = true
        view.backgroundColor = .black
        return view
    }

    func updateUIView(_ uiView: MTKView, context: Context) {}
}

import SwiftUI

/// 显式把 strokeIndex / phase 传进来，是为了让 SwiftUI 在状态变化时调用 updateUIView。
struct TalismanCanvas: UIViewRepresentable {
    let session: RitualSession
    let strokeIndex: Int
    let phase: RitualSession.Phase

    func makeUIView(context: Context) -> TalismanCanvasView {
        TalismanCanvasView(session: session)
    }

    func updateUIView(_ uiView: TalismanCanvasView, context: Context) {
        uiView.refresh()
    }
}

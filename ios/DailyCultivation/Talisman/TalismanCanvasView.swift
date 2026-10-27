import CoreHaptics
import TalismanKit
import UIKit

/// 画符画布。UIKit 而不是 SwiftUI，只为一件事：拿到 coalescedTouches。
/// DragGesture 的采样率与预测点都不可控，会直接毁掉"笔尖跟手"。
final class TalismanCanvasView: UIView {
    private let session: RitualSession

    private let faintLayer = CAShapeLayer()
    private let doneLayer = CAShapeLayer()
    private let guideLayer = CAShapeLayer()
    private let trailLayer = CAShapeLayer()
    private let dot = UIView()
    private let hintLabel = UILabel()
    private let plateNameLabel = UILabel()
    private let sealView = UIView()
    private let sealLabel = UILabel()
    private let inkLayer = CAGradientLayer()
    private let particles = RitualParticlesLayer()

    /// 不能叫 frame：UIView 已有 frame，同名重声明直接编译不过
    private var plateFrame: TalismanFrame?
    private var recorder = StrokeRecorder()
    private var isDrawing = false
    private var demoObserver: NSObjectProtocol?

    private let ink = UIColor(red: 0.09, green: 0.13, blue: 0.15, alpha: 1)
    private let cinnabar = UIColor(red: 0.557, green: 0.184, blue: 0.133, alpha: 1)

    init(session: RitualSession) {
        self.session = session
        super.init(frame: .zero)
        backgroundColor = .clear
        isMultipleTouchEnabled = false
        setupLayers()
        setupDot()
        setupHint()
        setupDecor()

        // 「示范」按钮：让画布自动画完当前一笔
        demoObserver = NotificationCenter.default.addObserver(
            forName: .demoStroke, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.drawDemoStroke() }
        }
    }

    deinit {
        if let demoObserver { NotificationCenter.default.removeObserver(demoObserver) }
    }

    /// 沿着当前笔的模板点画一遍，用于模拟器验收（鼠标拖拽采样太差）
    func drawDemoStroke() {
        guard session.phase == .drawing, let stroke = session.expectedStroke, stroke.count > 1 else { return }

        var dense: [Vec2] = []
        for i in 1..<stroke.count {
            let a = stroke[i - 1], b = stroke[i]
            let dx = b.x - a.x, dy = b.y - a.y
            let steps = max(2, Int((dx * dx + dy * dy).squareRoot() * 60))
            for s in 0..<steps {
                let t = Double(s) / Double(steps)
                dense.append(Vec2(x: a.x + dx * t, y: a.y + dy * t))
            }
        }
        if let last = stroke.last { dense.append(last) }

        let accepted = session.judge(dense)
        if accepted {
            UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.6)
            if session.phase == .settling, let pf = plateFrame {
                particles.fireBurst(at: CGPoint(x: pf.centerX, y: pf.centerY))
                animateSeal()
                animateInk()
            }
        }
        recorder.reset()
        trailLayer.path = nil
        refresh()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    // MARK: - 布局

    override func layoutSubviews() {
        super.layoutSubviews()
        // 符盘中心略高于屏幕中线：下方要留结算面板的位置
        // 292 是原型定稿值：符几乎贴到盘边，比例才像"一张符摊在盘上"
        let size = min(bounds.width * 0.78, 292)
        plateFrame = TalismanFrame(centerX: bounds.midX, centerY: bounds.height * 0.47, size: size)
        particles.frame = bounds
        if let plateFrame {
            let center = CGPoint(x: plateFrame.centerX, y: plateFrame.centerY)
            particles.configure(center: center, radius: plateFrame.size / 2)
            inkLayer.frame = CGRect(x: center.x - 180, y: center.y - 180, width: 360, height: 360)
            sealView.center = CGPoint(x: center.x + 48, y: center.y + 72)
            plateNameLabel.frame = CGRect(x: 0, y: center.y + 132, width: bounds.width, height: 18)
        }
        refresh()
    }

    /// SwiftUI 在 strokeIndex / phase 变化后调用，用来重画引导层。
    func refresh() {
        guard let plateFrame else { return }
        isUserInteractionEnabled = session.phase == .drawing
        drawStrokes(plateFrame)
        layoutDot(plateFrame)
        plateNameLabel.attributedText = NSAttributedString(
            string: "\(session.talisman.name) · \(session.talisman.strokes.count) 笔",
            attributes: [.kern: 3]
        )
        if session.phase == .drawing { clearDecor() }
        if !isDrawing { trailLayer.path = nil }
    }

    // MARK: - 图层

    private func setupLayers() {
        for layer in [faintLayer, doneLayer, trailLayer, guideLayer] {
            layer.fillColor = nil
            layer.lineCap = .round
            layer.lineJoin = .round
            self.layer.addSublayer(layer)
        }
        layer.addSublayer(particles)

        faintLayer.strokeColor = ink.withAlphaComponent(0.16).cgColor
        faintLayer.lineWidth = 1.6
        faintLayer.lineDashPattern = [5, 10]

        doneLayer.strokeColor = ink.withAlphaComponent(0.72).cgColor
        doneLayer.lineWidth = 2.2

        guideLayer.strokeColor = ink.withAlphaComponent(0.42).cgColor
        guideLayer.lineWidth = 2
        guideLayer.lineDashPattern = [6, 9]
        let flow = CABasicAnimation(keyPath: "lineDashPhase")
        flow.fromValue = 0
        flow.toValue = -30
        flow.duration = 2.4
        flow.repeatCount = .infinity
        guideLayer.add(flow, forKey: "flow")

        trailLayer.strokeColor = ink.withAlphaComponent(0.88).cgColor
        trailLayer.lineWidth = 5
        trailLayer.shadowColor = ink.withAlphaComponent(0.5).cgColor
        trailLayer.shadowRadius = 9
        trailLayer.shadowOpacity = 0.9
        trailLayer.shadowOffset = .zero
    }

    private func setupDot() {
        dot.isUserInteractionEnabled = false
        dot.backgroundColor = cinnabar
        dot.layer.cornerRadius = 7
        dot.layer.shadowColor = cinnabar.cgColor
        dot.layer.shadowRadius = 12
        dot.layer.shadowOpacity = 0.9
        dot.layer.shadowOffset = .zero
        dot.bounds = CGRect(x: 0, y: 0, width: 14, height: 14)
        addSubview(dot)

        let pulse = CABasicAnimation(keyPath: "transform.scale")
        pulse.fromValue = 1.0
        pulse.toValue = 1.45
        pulse.duration = 1.2
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        dot.layer.add(pulse, forKey: "pulse")
    }

    /// 宣纸般安静的装饰：极淡墨晕 + 落印 + 符名（宋体）。全部是纯代码，不占包体。
    private func setupDecor() {
        inkLayer.type = .radial
        inkLayer.colors = [cinnabar.withAlphaComponent(0.16).cgColor, UIColor.clear.cgColor]
        inkLayer.locations = [0, 0.7]
        inkLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        inkLayer.endPoint = CGPoint(x: 1, y: 1)
        inkLayer.opacity = 0
        layer.insertSublayer(inkLayer, at: 0)

        sealView.backgroundColor = cinnabar
        sealView.layer.cornerRadius = 3
        sealView.layer.borderWidth = 1
        sealView.layer.borderColor = UIColor(white: 1, alpha: 0.22).cgColor
        sealView.bounds = CGRect(x: 0, y: 0, width: 36, height: 36)
        sealView.alpha = 0
        sealView.isUserInteractionEnabled = false
        addSubview(sealView)

        sealLabel.text = "敕"
        sealLabel.font = UIFont(name: "Songti SC", size: 18) ?? .systemFont(ofSize: 18)
        sealLabel.textColor = UIColor(red: 0.95, green: 0.89, blue: 0.82, alpha: 1)
        sealLabel.textAlignment = .center
        sealLabel.frame = sealView.bounds
        sealView.addSubview(sealLabel)

        plateNameLabel.textAlignment = .center
        plateNameLabel.font = UIFont(name: "Songti SC", size: 12) ?? .systemFont(ofSize: 12)
        plateNameLabel.textColor = ink.withAlphaComponent(0.42)
        plateNameLabel.isUserInteractionEnabled = false
        addSubview(plateNameLabel)
    }

    private func setupHint() {
        hintLabel.font = .systemFont(ofSize: 12.5, weight: .regular)
        hintLabel.textColor = UIColor(white: 0.93, alpha: 0.55)
        hintLabel.textAlignment = .center
        hintLabel.alpha = 0
        hintLabel.isUserInteractionEnabled = false
        addSubview(hintLabel)
    }

    // MARK: - 绘制

    private func screenPoint(_ p: Vec2) -> CGPoint {
        guard let plateFrame else { return .zero }
        let originX = plateFrame.centerX - plateFrame.size / 2
        let originY = plateFrame.centerY - plateFrame.size / 2
        return CGPoint(x: originX + p.x * plateFrame.size, y: originY + p.y * plateFrame.size)
    }

    private func path(_ stroke: [Vec2]) -> UIBezierPath {
        let p = UIBezierPath()
        for (index, point) in stroke.enumerated() {
            let s = screenPoint(point)
            if index == 0 { p.move(to: s) } else { p.addLine(to: s) }
        }
        return p
    }

    private func drawStrokes(_ frame: TalismanFrame) {
        let strokes = session.talisman.strokes

        let faint = UIBezierPath()
        let done = UIBezierPath()
        let guide = UIBezierPath()

        for (index, stroke) in strokes.enumerated() {
            let p = path(stroke)
            if index < session.strokeIndex {
                done.append(p)
            } else if index == session.strokeIndex {
                guide.append(p)
            } else {
                faint.append(p)
            }
        }

        faintLayer.path = faint.isEmpty ? nil : faint.cgPath
        doneLayer.path = done.isEmpty ? nil : done.cgPath
        guideLayer.path = guide.isEmpty ? nil : guide.cgPath
    }

    private func layoutDot(_ frame: TalismanFrame) {
        guard let start = session.expectedStroke?.first else {
            dot.isHidden = true
            return
        }
        dot.isHidden = false
        dot.center = screenPoint(start)
    }

    private func updateTrail() {
        let points = recorder.points
        guard points.count > 1 else {
            trailLayer.path = nil
            return
        }
        let p = UIBezierPath()
        for (index, point) in points.enumerated() {
            let s = CGPoint(x: point.x, y: point.y)
            if index == 0 { p.move(to: s) } else { p.addLine(to: s) }
        }
        trailLayer.path = p.cgPath
    }

    // MARK: - 触摸

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard session.phase == .drawing,
              let touch = touches.first,
              let start = session.expectedStroke?.first else { return }

        let p = touch.location(in: self)
        let target = screenPoint(start)
        let distance = hypot(p.x - target.x, p.y - target.y)

        guard distance <= 40 else {
            showHint("从符头的光点起笔")
            return
        }

        recorder.begin(Vec2(x: Double(p.x), y: Double(p.y)), timestamp: touch.timestamp)
        isDrawing = true
        dot.isHidden = true
        particles.setTrailPoint(p, active: true)
        updateGaze(p)
        updateTrail()
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDrawing, let touch = touches.first else { return }

        // 120Hz 屏上，一次回调可能带来 2–3 个采样点；全丢就等于把 120Hz 降成 60Hz
        let samples = event?.coalescedTouches(for: touch) ?? [touch]
        for sample in samples {
            let p = sample.location(in: self)
            recorder.append(Vec2(x: Double(p.x), y: Double(p.y)), timestamp: sample.timestamp)
        }
        if let last = recorder.points.last {
            let point = CGPoint(x: last.x, y: last.y)
            particles.setTrailPoint(point, active: true)
            updateGaze(point)
        }
        updateTrail()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        finishStroke()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isDrawing = false
        recorder.reset()
        trailLayer.path = nil
        particles.setTrailPoint(.zero, active: false)
        updateGaze(nil)
        refresh()
    }

    private func finishStroke() {
        guard isDrawing, let plateFrame else { return }
        isDrawing = false
        updateGaze(nil)

        let points = recorder.points
        let length = recorder.length
        recorder.reset()
        trailLayer.path = nil
        particles.setTrailPoint(.zero, active: false)

        guard points.count >= 8, length >= 64 else {
            showHint("松手太早，这一笔作废")
            refresh()
            return
        }

        let local = points.map { plateFrame.local(from: $0) }
        let accepted = session.judge(local)
        if accepted {
            UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.6)
            if session.phase == .settling {
                particles.fireBurst(at: CGPoint(x: plateFrame.centerX, y: plateFrame.centerY))
                animateSeal()
                animateInk()
            }
        } else if let hint = session.hint {
            showHint(hint)
        }
        refresh()
    }

    // MARK: - 收尾装饰

    /// 落印：从 2.4 倍压到 1.0，回弹一次。整个 App 唯一的高光时刻就在这 0.46 秒。
    private func animateSeal() {
        sealView.layer.removeAllAnimations()
        sealView.alpha = 0
        sealView.transform = CGAffineTransform(rotationAngle: -0.24).scaledBy(x: 2.4, y: 2.4)
        UIView.animate(withDuration: 0.46,
                       delay: 0,
                       usingSpringWithDamping: 0.52,
                       initialSpringVelocity: 0.9,
                       options: [.curveEaseOut]) {
            self.sealView.alpha = 0.92
            self.sealView.transform = CGAffineTransform(rotationAngle: -0.1)
        }
    }

    /// 墨晕：一圈很淡的光从符心荡开，比多放 300 个粒子便宜得多。
    private func animateInk() {
        inkLayer.removeAllAnimations()
        inkLayer.opacity = 0

        let scale = CABasicAnimation(keyPath: "transform.scale")
        scale.fromValue = 0.4
        scale.toValue = 1.2

        let fade = CAKeyframeAnimation(keyPath: "opacity")
        fade.values = [0, 0.9, 0]
        fade.keyTimes = [0, 0.35, 1]

        let group = CAAnimationGroup()
        group.animations = [scale, fade]
        group.duration = 1.1
        group.timingFunction = CAMediaTimingFunction(name: .easeOut)
        inkLayer.add(group, forKey: "bloom")
    }

    private func clearDecor() {
        sealView.layer.removeAllAnimations()
        sealView.alpha = 0
        inkLayer.removeAllAnimations()
        inkLayer.opacity = 0
    }

    /// 指尖位置给宠物用：归一化到 -1…1，再压到 ±3pt 的瞳孔位移。
    private func updateGaze(_ point: CGPoint?) {
        guard let point, bounds.width > 0, bounds.height > 0 else {
            session.gaze = .zero
            return
        }
        let dx = (point.x - bounds.midX) / (bounds.width / 2)
        let dy = (point.y - bounds.midY) / (bounds.height / 2)
        session.gaze = CGSize(width: max(-3, min(3, dx * 3)),
                              height: max(-2, min(2, dy * 2)))
    }

    private func showHint(_ text: String) {
        hintLabel.text = text
        hintLabel.frame = CGRect(x: 0, y: bounds.height * 0.74, width: bounds.width, height: 20)
        UIView.animate(withDuration: 0.2, animations: { self.hintLabel.alpha = 0.8 }) { _ in
            UIView.animate(withDuration: 0.4, delay: 1.2, options: [], animations: {
                self.hintLabel.alpha = 0
            })
        }
    }
}

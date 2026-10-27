import QuartzCore
import UIKit

/// 三组粒子：环境灵气（常驻）、指尖星尘（画符时）、结算爆发（一次）。
/// V1 用 CAEmitterLayer 而不是自写 Metal 粒子：
/// 手写粒子系统至少多 5 天，而 V1 只需要"亮一下"。
final class RitualParticlesLayer: CALayer {
    private let ambient = CAEmitterLayer()
    private let trail = CAEmitterLayer()
    private let burst = CAEmitterLayer()

    private let gold = UIColor(red: 1.0, green: 0.92, blue: 0.76, alpha: 1)
    private let jade = UIColor(red: 0.62, green: 0.85, blue: 0.80, alpha: 1)

    override init() {
        super.init()
        setupEmitters()
        addSublayer(ambient)
        addSublayer(trail)
        addSublayer(burst)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    private func setupEmitters() {
        for emitter in [ambient, trail, burst] {
            emitter.renderMode = .additive
            emitter.emitterShape = .circle
            emitter.emitterMode = .surface
        }

        // 环境灵气：缓慢上浮，数量少，长寿命
        let dust = CAEmitterCell()
        dust.contents = ParticleTexture.dot(color: gold)
        dust.birthRate = 1
        dust.lifetime = 9
        dust.velocity = 7
        dust.velocityRange = 5
        dust.emissionRange = .pi * 2
        dust.scale = 0.06
        dust.scaleRange = 0.04
        dust.scaleSpeed = -0.004
        dust.alphaSpeed = -0.09
        dust.color = gold.withAlphaComponent(0.55).cgColor
        ambient.emitterCells = [dust]
        ambient.birthRate = 1

        // 指尖星尘：短寿命、小、跟着手指
        let spark = CAEmitterCell()
        spark.contents = ParticleTexture.dot(color: gold)
        spark.birthRate = 1
        spark.lifetime = 0.55
        spark.velocity = 34
        spark.velocityRange = 22
        spark.emissionRange = .pi * 2
        spark.scale = 0.05
        spark.scaleRange = 0.035
        spark.scaleSpeed = -0.06
        spark.alphaSpeed = -2.2
        spark.yAcceleration = -18
        trail.emitterCells = [spark]
        trail.birthRate = 0
        trail.emitterShape = .point

        // 结算爆发：一次性
        let burstCell = CAEmitterCell()
        burstCell.contents = ParticleTexture.dot(color: gold)
        burstCell.birthRate = 1
        burstCell.lifetime = 1.1
        burstCell.velocity = 250
        burstCell.velocityRange = 150
        burstCell.emissionRange = .pi * 2
        burstCell.scale = 0.09
        burstCell.scaleRange = 0.05
        burstCell.scaleSpeed = -0.05
        burstCell.alphaSpeed = -0.9
        burstCell.yAcceleration = 60

        let jadeCell = CAEmitterCell()
        jadeCell.contents = ParticleTexture.dot(color: jade)
        jadeCell.birthRate = 1
        jadeCell.lifetime = 0.9
        jadeCell.velocity = 180
        jadeCell.velocityRange = 120
        jadeCell.emissionRange = .pi * 2
        jadeCell.scale = 0.06
        jadeCell.scaleRange = 0.03
        jadeCell.alphaSpeed = -1.2

        burst.emitterCells = [burstCell, jadeCell]
    }

    /// 布局变化时调用：粒子半径随符盘尺寸走。
    func configure(center: CGPoint, radius: CGFloat) {
        ambient.emitterPosition = center
        ambient.emitterSize = CGSize(width: radius * 1.6, height: radius * 1.6)
        ambient.birthRate = 1

        trail.emitterPosition = center
        burst.emitterPosition = center
        burst.emitterSize = CGSize(width: 12, height: 12)
    }

    func setTrailPoint(_ point: CGPoint, active: Bool) {
        trail.emitterPosition = point
        trail.birthRate = active ? 90 : 0
    }

    /// 一次爆发：0.12s 内把 birthRate 拉高再关掉，避免常驻开销。
    func fireBurst(at point: CGPoint) {
        burst.emitterPosition = point
        burst.birthRate = 900
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            self?.burst.birthRate = 0
        }
    }
}

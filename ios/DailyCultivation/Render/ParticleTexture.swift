import UIKit

enum ParticleTexture {
    private static var cache: [String: CGImage] = [:]

    /// 程序生成柔光点，避免为占位粒子引入图片资源。
    static func dot(color: UIColor, diameter: CGFloat = 32) -> CGImage? {
        let key = "\(color.description)-\(diameter)"
        if let cached = cache[key] { return cached }

        let size = CGSize(width: diameter, height: diameter)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            let cg = context.cgContext
            let colors = [color.cgColor, color.withAlphaComponent(0).cgColor] as CFArray
            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                            colors: colors,
                                            locations: [0, 1]) else { return }
            let center = CGPoint(x: diameter / 2, y: diameter / 2)
            cg.drawRadialGradient(gradient,
                                  startCenter: center, startRadius: 0,
                                  endCenter: center, endRadius: diameter / 2,
                                  options: [])
        }
        cache[key] = image.cgImage
        return image.cgImage
    }
}

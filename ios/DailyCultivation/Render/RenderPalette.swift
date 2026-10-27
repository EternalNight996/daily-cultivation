import CoreGraphics

/// 四时辰的调色参数。改的是真实画面（色温/饱和/辉光/暗角），不是盖一层半透明色块——
/// 盖色块会把暗部细节一起洗掉，在真机上看起来像"滤镜坏了"。
struct RenderPalette: Equatable {
    var targetNeutral: CGFloat     // CITemperatureAndTint 的目标色温：数值越低越暖
    var saturation: CGFloat
    var contrast: CGFloat
    var bloomIntensity: CGFloat
    var bloomRadius: CGFloat
    var vignetteIntensity: CGFloat

    static func forShichen(_ shichen: Shichen) -> RenderPalette {
        switch shichen {
        case .zi:
            // 玄水：冷、对比高、辉光偏紧
            return RenderPalette(targetNeutral: 7600, saturation: 0.86, contrast: 1.10,
                                 bloomIntensity: 0.40, bloomRadius: 7, vignetteIntensity: 0.92)
        case .mao:
            // 青木：清晨的通透感，饱和略高
            return RenderPalette(targetNeutral: 5600, saturation: 1.02, contrast: 1.04,
                                 bloomIntensity: 0.36, bloomRadius: 8, vignetteIntensity: 0.74)
        case .wu:
            // 离火：暖金、辉光最亮
            return RenderPalette(targetNeutral: 5000, saturation: 0.98, contrast: 1.06,
                                 bloomIntensity: 0.46, bloomRadius: 9, vignetteIntensity: 0.80)
        case .you:
            // 白金：偏中性、克制的金属感
            return RenderPalette(targetNeutral: 6200, saturation: 0.92, contrast: 1.05,
                                 bloomIntensity: 0.30, bloomRadius: 7, vignetteIntensity: 0.78)
        case .chang:
            // 无常：不抢戏，作为默认
            return RenderPalette(targetNeutral: 6500, saturation: 0.95, contrast: 1.03,
                                 bloomIntensity: 0.30, bloomRadius: 7, vignetteIntensity: 0.72)
        }
    }
}

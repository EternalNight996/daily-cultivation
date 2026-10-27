import SwiftUI
import UIKit

struct PermissionView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openURL) private var openURL

    private let ink = Color(red: 0.086, green: 0.125, blue: 0.145)
    private let cinnabar = Color(red: 0.557, green: 0.184, blue: 0.133)

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Text("洞府未开")
                .font(.system(size: 26, weight: .light))
                .tracking(8)
                .foregroundStyle(ink)

            Text(bodyText)
                .font(.system(size: 13))
                .lineSpacing(7)
                .multilineTextAlignment(.center)
                .foregroundStyle(ink.opacity(0.55))
                .padding(.horizontal, 46)
                .padding(.top, 18)

            Button(action: primaryAction) {
                Text(title)
                    .font(.system(size: 14))
                    .tracking(3)
                    .foregroundStyle(cinnabar)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(cinnabar.opacity(0.45), lineWidth: 1)
                    )
            }
            .padding(.horizontal, 48)
            .padding(.top, 34)

            Text("画面只在这台 iPhone 上处理，不上传、不保存。")
                .font(.system(size: 11))
                .foregroundStyle(ink.opacity(0.4))
                .padding(.top, 16)

            if model.permission == .denied || model.permission == .restricted {
                Button("以水墨洞府继续") {
                    model.inkOnly = true
                }
                .font(.system(size: 13))
                .foregroundStyle(ink.opacity(0.5))
                .padding(.top, 22)
            }

            Spacer()
            Spacer()
        }
        .background(InkBackground().ignoresSafeArea())
    }

    private var title: String {
        switch model.permission {
        case .notDetermined: return "开启灵镜"
        case .denied: return "前往设置"
        case .restricted: return "了解详情"
        case .authorized: return ""
        }
    }

    private var bodyText: String {
        switch model.permission {
        case .notDetermined:
            return "施法需要把眼前的景象化作洞府。\n先开灵镜，再落笔成符。"
        case .denied:
            return "灵镜被关闭了。\n可以在「设置 → 每日一道符 → 相机」里重新开启。"
        case .restricted:
            return "这台设备限制了相机访问。\n你仍然可以用水墨洞府完成施法。"
        case .authorized:
            return ""
        }
    }

    private func primaryAction() {
        switch model.permission {
        case .notDetermined:
            Task { await model.requestCamera() }
        case .denied:
            if let url = URL(string: UIApplication.openSettingsURLString) {
                openURL(url)
            }
        case .restricted:
            model.inkOnly = true         // 受限设备直接走水墨降级
        case .authorized:
            break
        }
    }
}

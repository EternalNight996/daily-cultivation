import OSLog

enum AppLog {
    static let capture = Logger(subsystem: "com.dailycultivation.app", category: "capture")
    static let render = Logger(subsystem: "com.dailycultivation.app", category: "render")
    static let ritual = Logger(subsystem: "com.dailycultivation.app", category: "ritual")
    static let store = Logger(subsystem: "com.dailycultivation.app", category: "store")
}

import AVFoundation

enum CameraPermission: Equatable {
    case notDetermined
    case authorized
    case denied
    case restricted

    static var current: CameraPermission {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: return .authorized
        case .denied: return .denied
        case .restricted: return .restricted
        case .notDetermined: return .notDetermined
        @unknown default: return .denied
        }
    }
}

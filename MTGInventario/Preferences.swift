import Foundation

/// Equivalente a `Preferences.kt`. Android usaba `SharedPreferences`; en iOS
/// el equivalente directo es `UserDefaults`.
enum Preferences {
    private static let keyServerUrl = "server_url"
    private static let defaultUrl = "http://192.168.1.100:5000"

    static func getServerUrl() -> String {
        UserDefaults.standard.string(forKey: keyServerUrl) ?? defaultUrl
    }

    static func setServerUrl(_ url: String) {
        UserDefaults.standard.set(url.trimmingCharacters(in: .whitespacesAndNewlines), forKey: keyServerUrl)
    }
}

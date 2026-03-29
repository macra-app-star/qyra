import SwiftUI

@Observable @MainActor
final class ThemeManager {
    enum Mode: String, CaseIterable {
        case system, light, dark

        var label: String {
            switch self {
            case .system: return "System"
            case .light: return "Light"
            case .dark: return "Dark"
            }
        }
    }

    var mode: Mode {
        didSet { UserDefaults.standard.set(mode.rawValue, forKey: "app_theme_mode") }
    }

    var resolvedColorScheme: ColorScheme? {
        switch mode {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    init() {
        let saved = UserDefaults.standard.string(forKey: "app_theme_mode") ?? "light"
        self.mode = Mode(rawValue: saved) ?? .system
    }
}

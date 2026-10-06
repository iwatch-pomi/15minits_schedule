import SwiftUI

/// @AppStorage で使う設定キーと既定値
enum AppSettings {
    static let themeKey = "themeMode"
    static let timelineStartHourKey = "timelineStartHour"
    static let timelineEndHourKey = "timelineEndHour"
    static let defaultDurationKey = "defaultDurationMinutes"
    static let defaultCategoryKey = "defaultCategory"
    static let notificationsEnabledKey = "notificationsEnabled"

    static let defaultTimelineStartHour = 6
    static let defaultTimelineEndHour = 24
    static let defaultDuration = 30

    static let durationChoices = [15, 30, 45, 60, 90, 120]

    /// UserDefaults から直接読む（View 外で使う用）
    static var currentDefaultDuration: Int {
        UserDefaults.standard.object(forKey: defaultDurationKey) as? Int ?? defaultDuration
    }

    static var currentDefaultCategory: TaskCategory {
        TaskCategory(rawValue: UserDefaults.standard.string(forKey: defaultCategoryKey) ?? "") ?? .study
    }
}

enum ThemeMode: String, CaseIterable, Identifiable {
    case light
    case dark
    case system

    var id: String { rawValue }

    var label: String {
        switch self {
        case .light: return "ライト"
        case .dark: return "ダーク"
        case .system: return "端末に合わせる"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}

import Foundation

extension Calendar {
    /// アプリ全体で使うカレンダー（月曜始まり・日本語）
    static let app: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "ja_JP")
        calendar.timeZone = .current
        calendar.firstWeekday = 2
        return calendar
    }()
}

/// 15分単位の時刻計算
enum QuarterHour {
    static let step = 15
    static let minutesPerDay = 24 * 60

    /// その日の 0:00 からの経過分
    static func minutes(from date: Date) -> Int {
        let parts = Calendar.app.dateComponents([.hour, .minute], from: date)
        return (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
    }

    /// 15分単位に切り捨て
    static func floor(_ minutes: Int) -> Int {
        (minutes / step) * step
    }

    /// 15分単位に切り上げ
    static func ceil(_ minutes: Int) -> Int {
        ((minutes + step - 1) / step) * step
    }

    /// day の 0:00 から minutes 分後の日時
    static func date(on day: Date, minutes: Int) -> Date {
        let start = Calendar.app.startOfDay(for: day)
        return Calendar.app.date(byAdding: .minute, value: minutes, to: start) ?? start
    }

    /// "9:15" / "24:00" のような表記
    static func label(_ minutes: Int) -> String {
        String(format: "%d:%02d", minutes / 60, minutes % 60)
    }

    /// "1時間15分" のような表記
    static func durationText(_ minutes: Int) -> String {
        let hours = minutes / 60
        let rest = minutes % 60
        if hours == 0 { return "\(rest)分" }
        if rest == 0 { return "\(hours)時間" }
        return "\(hours)時間\(rest)分"
    }
}

/// 日付の表示用フォーマッタ
enum DateText {
    private static func formatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.app
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = format
        return formatter
    }

    private static let monthFormatter = formatter("yyyy年M月")
    private static let dayFormatter = formatter("M月d日（E）")
    private static let timeFormatter = formatter("H:mm")

    static func month(_ date: Date) -> String { monthFormatter.string(from: date) }
    static func day(_ date: Date) -> String { dayFormatter.string(from: date) }
    static func time(_ date: Date) -> String { timeFormatter.string(from: date) }
}

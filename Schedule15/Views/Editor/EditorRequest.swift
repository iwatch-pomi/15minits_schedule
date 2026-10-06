import Foundation

/// タスク編集シートを開くためのリクエスト
struct EditorRequest: Identifiable {
    let id = UUID()
    let task: TaskItem?
    let day: Date
    let startMinutes: Int
    let endMinutes: Int
    let category: TaskCategory

    /// 新規タスク（start を 15 分単位に丸め、既定の所要時間を使う）
    static func new(at start: Date) -> EditorRequest {
        let day = Calendar.app.startOfDay(for: start)
        let startMinutes = min(QuarterHour.floor(QuarterHour.minutes(from: start)),
                               QuarterHour.minutesPerDay - QuarterHour.step)
        let endMinutes = min(startMinutes + AppSettings.currentDefaultDuration, QuarterHour.minutesPerDay)
        return EditorRequest(task: nil, day: day, startMinutes: startMinutes,
                             endMinutes: endMinutes, category: AppSettings.currentDefaultCategory)
    }

    /// 指定日の「次に始めやすい時刻」で新規タスク
    static func new(on day: Date) -> EditorRequest {
        let calendar = Calendar.app
        if calendar.isDateInToday(day) {
            let next = QuarterHour.ceil(QuarterHour.minutes(from: .now))
            return new(at: QuarterHour.date(on: day, minutes: next))
        }
        return new(at: QuarterHour.date(on: day, minutes: 9 * 60))
    }

    static func edit(_ task: TaskItem) -> EditorRequest {
        let startMinutes = QuarterHour.floor(QuarterHour.minutes(from: task.start))
        let endMinutes = min(startMinutes + max(task.durationMinutes, QuarterHour.step), QuarterHour.minutesPerDay)
        return EditorRequest(task: task, day: Calendar.app.startOfDay(for: task.start),
                             startMinutes: startMinutes, endMinutes: QuarterHour.ceil(endMinutes),
                             category: task.category)
    }
}

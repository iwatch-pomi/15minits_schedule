import Foundation
import SwiftData

@Model
final class TaskItem {
    var title: String
    var start: Date
    var end: Date
    var categoryRaw: String
    var iconName: String
    var memo: String
    var isCompleted: Bool
    var createdAt: Date

    init(
        title: String,
        start: Date,
        end: Date,
        category: TaskCategory,
        iconName: String? = nil,
        memo: String = "",
        isCompleted: Bool = false
    ) {
        self.title = title
        self.start = start
        self.end = end
        self.categoryRaw = category.rawValue
        self.iconName = iconName ?? category.defaultIcon
        self.memo = memo
        self.isCompleted = isCompleted
        self.createdAt = .now
    }

    var category: TaskCategory {
        get { TaskCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    /// 所要時間（分）
    var durationMinutes: Int {
        max(0, Int(end.timeIntervalSince(start) / 60))
    }

    var timeRangeText: String {
        "\(DateText.time(start)) - \(DateText.time(end))"
    }
}

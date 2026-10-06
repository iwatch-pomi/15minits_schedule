import SwiftUI

/// タスク一覧・カレンダーで使う 1 行
struct TaskRowView: View {
    let task: TaskItem

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(DateText.time(task.start))
                    .font(.subheadline.weight(.semibold))
                Text(QuarterHour.durationText(task.durationMinutes))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .monospacedDigit()
            .frame(width: 54, alignment: .leading)
            .foregroundStyle(task.isCompleted ? Color.secondary : Color.accentColor)

            Image(systemName: task.iconName)
                .foregroundStyle(task.category.color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.body)
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? Color.secondary : Color.primary)
                    .lineLimit(1)
                if !task.memo.isEmpty {
                    Text(task.memo)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)
            CategoryDot(category: task.category, size: 8)
        }
        .contentShape(Rectangle())
    }
}

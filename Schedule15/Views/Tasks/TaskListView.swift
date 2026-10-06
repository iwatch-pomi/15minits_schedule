import SwiftUI
import SwiftData

/// タスク一覧：フィルタ＋チェックで完了
struct TaskListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskItem.start) private var tasks: [TaskItem]

    @State private var filter: TaskFilter = .today
    @State private var editor: EditorRequest?

    private let calendar = Calendar.app

    enum TaskFilter: String, CaseIterable, Identifiable {
        case all, today, incomplete, completed
        var id: String { rawValue }
        var label: String {
            switch self {
            case .all: return "すべて"
            case .today: return "今日"
            case .incomplete: return "未完了"
            case .completed: return "完了"
            }
        }
    }

    private var filteredTasks: [TaskItem] {
        switch filter {
        case .all: return tasks
        case .today: return tasks.filter { calendar.isDateInToday($0.start) }
        case .incomplete: return tasks.filter { !$0.isCompleted }
        case .completed: return tasks.filter { $0.isCompleted }
        }
    }

    struct DaySection: Identifiable {
        let day: Date
        let tasks: [TaskItem]
        var id: Date { day }
    }

    /// 日付ごとのセクション
    private var sections: [DaySection] {
        let grouped = Dictionary(grouping: filteredTasks) { calendar.startOfDay(for: $0.start) }
        return grouped.keys.sorted().map { DaySection(day: $0, tasks: grouped[$0] ?? []) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterBar
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)

                if sections.isEmpty {
                    ContentUnavailableView {
                        Label("タスクがありません", systemImage: "checklist")
                    } description: {
                        Text("右下の＋ボタンから15分単位でタスクを追加できます。")
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    List {
                        ForEach(sections) { section in
                            Section {
                                ForEach(section.tasks) { task in
                                    row(task)
                                }
                                .onDelete { offsets in
                                    delete(offsets.map { section.tasks[$0] })
                                }
                            } header: {
                                Text(sectionTitle(section.day))
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .background(AppColor.background)
            .overlay(alignment: .bottomTrailing) {
                FloatingAddButton { editor = .new(on: .now) }
            }
            .navigationTitle("タスク")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $editor) { request in
                TaskEditorView(request: request)
            }
        }
    }

    private var filterBar: some View {
        HStack(spacing: 8) {
            ForEach(TaskFilter.allCases) { item in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { filter = item }
                } label: {
                    Text(item.label)
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .foregroundStyle(filter == item ? Color.white : Color.secondary)
                        .background(
                            Capsule().fill(filter == item ? Color.accentColor : Color(.tertiarySystemFill))
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func row(_ task: TaskItem) -> some View {
        HStack(spacing: 12) {
            Button {
                withAnimation { task.isCompleted.toggle() }
                try? modelContext.save()
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundStyle(task.isCompleted ? Color.accentColor : Color.secondary)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(task.isCompleted ? "未完了に戻す" : "完了にする")

            Button {
                editor = .edit(task)
            } label: {
                TaskRowView(task: task)
            }
            .buttonStyle(.plain)
        }
        .listRowBackground(task.isCompleted ? Color.accentColor.opacity(0.06) : AppColor.card)
    }

    private func sectionTitle(_ day: Date) -> String {
        if calendar.isDateInToday(day) { return "今日 " + DateText.day(day) }
        if calendar.isDateInTomorrow(day) { return "明日 " + DateText.day(day) }
        if calendar.isDateInYesterday(day) { return "昨日 " + DateText.day(day) }
        return DateText.day(day)
    }

    private func delete(_ items: [TaskItem]) {
        for item in items {
            modelContext.delete(item)
        }
        try? modelContext.save()
    }
}

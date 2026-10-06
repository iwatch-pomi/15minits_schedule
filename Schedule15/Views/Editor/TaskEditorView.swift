import SwiftUI
import SwiftData

/// 新規作成・編集シート
struct TaskEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private let task: TaskItem?

    @State private var title: String
    @State private var day: Date
    @State private var startMinutes: Int
    @State private var endMinutes: Int
    @State private var category: TaskCategory
    @State private var iconName: String
    @State private var memo: String
    @State private var isCompleted: Bool
    @State private var editingField: TimeField?
    @State private var showDeleteConfirm = false
    @FocusState private var titleFocused: Bool

    private enum TimeField {
        case start, end
    }

    init(request: EditorRequest) {
        task = request.task
        _title = State(initialValue: request.task?.title ?? "")
        _day = State(initialValue: request.day)
        _startMinutes = State(initialValue: request.startMinutes)
        _endMinutes = State(initialValue: max(request.endMinutes, request.startMinutes + QuarterHour.step))
        _category = State(initialValue: request.category)
        _iconName = State(initialValue: request.task?.iconName ?? request.category.defaultIcon)
        _memo = State(initialValue: request.task?.memo ?? "")
        _isCompleted = State(initialValue: request.task?.isCompleted ?? false)
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && endMinutes > startMinutes
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("タスク名（例：レポート作成）", text: $title)
                        .focused($titleFocused)
                }

                Section("日時") {
                    DatePicker("日付", selection: $day, displayedComponents: .date)

                    HStack(spacing: 12) {
                        timeButton(caption: "開始時間", minutes: startMinutes, field: .start)
                        timeButton(caption: "終了時間", minutes: endMinutes, field: .end)
                    }

                    if let field = editingField {
                        Picker("時刻", selection: field == .start ? $startMinutes : $endMinutes) {
                            ForEach(options(for: field), id: \.self) { minutes in
                                Text(QuarterHour.label(minutes)).tag(minutes)
                            }
                        }
                        .pickerStyle(.wheel)
                        .labelsHidden()
                        .id(field == .start ? "start" : "end")
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("所要時間")
                            Spacer()
                            Text(QuarterHour.durationText(endMinutes - startMinutes))
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(AppSettings.durationChoices, id: \.self) { minutes in
                                    durationChip(minutes)
                                }
                            }
                        }
                    }
                }

                Section("カテゴリ") {
                    ForEach(TaskCategory.allCases) { item in
                        Button {
                            selectCategory(item)
                        } label: {
                            HStack(spacing: 12) {
                                CategoryDot(category: item, size: 14)
                                Text(item.label)
                                    .foregroundStyle(Color.primary)
                                Spacer()
                                if category == item {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                        }
                    }
                }

                Section("アイコン") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                        ForEach(TaskIcons.all, id: \.self) { name in
                            Button {
                                iconName = name
                            } label: {
                                Image(systemName: name)
                                    .font(.title3)
                                    .frame(width: 44, height: 44)
                                    .foregroundStyle(iconName == name ? Color.white : category.color)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(iconName == name ? category.color : category.color.opacity(0.12))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("メモ（任意）") {
                    TextField("メモを入力…", text: $memo, axis: .vertical)
                        .lineLimit(3...6)
                }

                if task != nil {
                    Section {
                        Toggle("完了", isOn: $isCompleted)
                    }
                    Section {
                        Button("このタスクを削除", role: .destructive) {
                            showDeleteConfirm = true
                        }
                    }
                }
            }
            .navigationTitle(task == nil ? "新規タスク" : "タスクを編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
            .onChange(of: startMinutes) { oldValue, newValue in
                // 開始時刻を動かしたら所要時間を保ったまま終了時刻もずらす
                let duration = max(endMinutes - oldValue, QuarterHour.step)
                endMinutes = min(newValue + duration, QuarterHour.minutesPerDay)
            }
            .confirmationDialog("このタスクを削除しますか？", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("削除", role: .destructive) { deleteTask() }
            }
            .onAppear {
                if task == nil { titleFocused = true }
            }
        }
    }

    // MARK: - Parts

    private func timeButton(caption: String, minutes: Int, field: TimeField) -> some View {
        let isEditing = editingField == field
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                editingField = isEditing ? nil : field
            }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                    Text(QuarterHour.label(minutes))
                        .font(.title3.weight(.semibold))
                        .monospacedDigit()
                    Spacer(minLength: 0)
                    Image(systemName: isEditing ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(isEditing ? Color.accentColor : Color.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isEditing ? Color.accentColor.opacity(0.12) : Color(.tertiarySystemFill))
                )
            }
        }
        .buttonStyle(.plain)
    }

    private func durationChip(_ minutes: Int) -> some View {
        let isSelected = endMinutes - startMinutes == minutes
        let fits = startMinutes + minutes <= QuarterHour.minutesPerDay
        return Button {
            endMinutes = startMinutes + minutes
        } label: {
            Text(QuarterHour.durationText(minutes))
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .foregroundStyle(isSelected ? Color.white : Color.accentColor)
                .background(Capsule().fill(isSelected ? Color.accentColor : Color.accentColor.opacity(0.12)))
        }
        .buttonStyle(.plain)
        .disabled(!fits)
        .opacity(fits ? 1 : 0.4)
    }

    private func options(for field: TimeField) -> [Int] {
        switch field {
        case .start:
            return Array(stride(from: 0, to: QuarterHour.minutesPerDay, by: QuarterHour.step))
        case .end:
            return Array(stride(from: startMinutes + QuarterHour.step,
                                through: QuarterHour.minutesPerDay,
                                by: QuarterHour.step))
        }
    }

    private func selectCategory(_ item: TaskCategory) {
        // アイコンがカテゴリ既定のままなら新しいカテゴリの既定アイコンに合わせる
        if iconName == category.defaultIcon {
            iconName = item.defaultIcon
        }
        category = item
    }

    // MARK: - Actions

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let start = QuarterHour.date(on: day, minutes: startMinutes)
        let end = QuarterHour.date(on: day, minutes: endMinutes)
        let trimmedMemo = memo.trimmingCharacters(in: .whitespacesAndNewlines)

        if let task {
            task.title = trimmed
            task.start = start
            task.end = end
            task.category = category
            task.iconName = iconName
            task.memo = trimmedMemo
            task.isCompleted = isCompleted
        } else {
            let newTask = TaskItem(title: trimmed, start: start, end: end, category: category,
                                   iconName: iconName, memo: trimmedMemo)
            modelContext.insert(newTask)
        }
        try? modelContext.save()
        dismiss()
    }

    private func deleteTask() {
        if let task {
            modelContext.delete(task)
            try? modelContext.save()
        }
        dismiss()
    }
}

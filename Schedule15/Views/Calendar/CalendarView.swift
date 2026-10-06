import SwiftUI
import SwiftData

/// 月カレンダー＋選択日のタスク一覧
struct CalendarView: View {
    @Binding var selectedDate: Date
    @Query(sort: \TaskItem.start) private var tasks: [TaskItem]

    @State private var displayedMonth: Date = .now
    @State private var editor: EditorRequest?

    private let calendar = Calendar.app
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    private var monthStart: Date {
        calendar.dateInterval(of: .month, for: displayedMonth)?.start ?? displayedMonth
    }

    /// 先頭の空白（nil）＋その月の日付
    private var monthCells: [Date?] {
        guard let days = calendar.range(of: .day, in: .month, for: monthStart) else { return [] }
        let weekday = calendar.component(.weekday, from: monthStart)
        let leading = (weekday - calendar.firstWeekday + 7) % 7
        let dates: [Date?] = days.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: monthStart) }
        return Array(repeating: nil, count: leading) + dates
    }

    /// 曜日見出し（月曜始まり）
    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortWeekdaySymbols
        let first = calendar.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }

    private var minutesByDay: [Date: Int] {
        var result: [Date: Int] = [:]
        for task in tasks {
            result[calendar.startOfDay(for: task.start), default: 0] += task.durationMinutes
        }
        return result
    }

    private var dayTasks: [TaskItem] {
        tasks.filter { calendar.isDate($0.start, inSameDayAs: selectedDate) }
    }

    private var dayTotalMinutes: Int {
        dayTasks.reduce(0) { $0 + $1.durationMinutes }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    monthGrid
                        .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                }

                Section {
                    if dayTasks.isEmpty {
                        Text("予定はありません")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(dayTasks) { task in
                            Button {
                                editor = .edit(task)
                            } label: {
                                TaskRowView(task: task)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } header: {
                    HStack {
                        Text(DateText.day(selectedDate))
                        Spacer()
                        if !dayTasks.isEmpty {
                            Text("合計 " + QuarterHour.durationText(dayTotalMinutes))
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(DateText.month(displayedMonth))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("今日") {
                        withAnimation {
                            selectedDate = .now
                            displayedMonth = .now
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { editor = .new(on: selectedDate) } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("タスクを追加")
                }
            }
            .sheet(item: $editor) { request in
                TaskEditorView(request: request)
            }
            .onAppear { displayedMonth = selectedDate }
        }
    }

    private var monthGrid: some View {
        VStack(spacing: 8) {
            HStack {
                Button { shiftMonth(-1) } label: {
                    Image(systemName: "chevron.left").frame(width: 36, height: 32)
                }
                .buttonStyle(.borderless)
                Spacer()
                Text(DateText.month(displayedMonth))
                    .font(.headline)
                Spacer()
                Button { shiftMonth(1) } label: {
                    Image(systemName: "chevron.right").frame(width: 36, height: 32)
                }
                .buttonStyle(.borderless)
            }

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { index, symbol in
                    Text(symbol)
                        .font(.caption)
                        .foregroundStyle(index == 5 ? Color.blue.opacity(0.8) : (index == 6 ? Color.red.opacity(0.8) : Color.secondary))
                        .frame(maxWidth: .infinity)
                }
                ForEach(Array(monthCells.enumerated()), id: \.offset) { _, day in
                    if let day {
                        dayCell(day)
                    } else {
                        Color.clear.frame(height: 44)
                    }
                }
            }
        }
        .gesture(
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    if value.translation.width < -50 { shiftMonth(1) }
                    if value.translation.width > 50 { shiftMonth(-1) }
                }
        )
    }

    private func dayCell(_ day: Date) -> some View {
        let isSelected = calendar.isDate(day, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(day)
        let minutes = minutesByDay[calendar.startOfDay(for: day)] ?? 0

        return Button {
            withAnimation(.easeInOut(duration: 0.15)) { selectedDate = day }
        } label: {
            VStack(spacing: 3) {
                Text("\(calendar.component(.day, from: day))")
                    .font(.callout.weight(isSelected || isToday ? .bold : .regular))
                    .monospacedDigit()
                    .frame(width: 34, height: 34)
                    .foregroundStyle(isSelected ? Color.white : (isToday ? Color.accentColor : Color.primary))
                    .background(Circle().fill(isSelected ? Color.accentColor : Color.clear))
                // 予定の量に応じてドットの濃さを変える
                Circle()
                    .fill(minutes > 0 ? Color.accentColor.opacity(min(0.3 + Double(minutes) / 480, 1)) : Color.clear)
                    .frame(width: 5, height: 5)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func shiftMonth(_ amount: Int) {
        if let date = calendar.date(byAdding: .month, value: amount, to: displayedMonth) {
            withAnimation(.easeInOut(duration: 0.2)) { displayedMonth = date }
        }
    }
}

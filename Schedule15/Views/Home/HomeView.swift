import SwiftUI
import SwiftData

/// ホーム：週ストリップ＋15分タイムライン
struct HomeView: View {
    @Binding var selectedDate: Date
    @Query(sort: \TaskItem.start) private var tasks: [TaskItem]

    @State private var editor: EditorRequest?
    @State private var showStats = false

    private let calendar = Calendar.app

    private var dayTasks: [TaskItem] {
        tasks.filter { calendar.isDate($0.start, inSameDayAs: selectedDate) }
    }

    private var dayTotalMinutes: Int {
        dayTasks.reduce(0) { $0 + $1.durationMinutes }
    }

    private var markedDays: Set<Date> {
        Set(tasks.map { calendar.startOfDay(for: $0.start) })
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                WeekStripView(selectedDate: $selectedDate, markedDays: markedDays)
                    .padding(.bottom, 4)

                Divider()

                HStack(alignment: .firstTextBaseline) {
                    Text(DateText.day(selectedDate))
                        .font(.title3.weight(.bold))
                    if !dayTasks.isEmpty {
                        Text("\(dayTasks.count)件・" + QuarterHour.durationText(dayTotalMinutes))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if !calendar.isDateInToday(selectedDate) {
                        Button("今日") {
                            withAnimation { selectedDate = .now }
                        }
                        .font(.subheadline.weight(.semibold))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                DayTimelineView(
                    date: selectedDate,
                    tasks: dayTasks,
                    onTapSlot: { editor = .new(at: $0) },
                    onTapTask: { editor = .edit($0) }
                )
            }
            .overlay(alignment: .bottomTrailing) {
                FloatingAddButton { editor = .new(on: selectedDate) }
            }
            .navigationTitle(DateText.month(selectedDate))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showStats = true } label: {
                        Image(systemName: "chart.bar")
                    }
                    .accessibilityLabel("時間の使い方")
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
            .sheet(isPresented: $showStats) {
                StatsView(initialDate: selectedDate)
            }
        }
    }
}

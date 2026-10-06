import SwiftUI

/// 月〜日の 1 週間を横に並べた日付選択
struct WeekStripView: View {
    @Binding var selectedDate: Date
    let markedDays: Set<Date>

    private let calendar = Calendar.app

    private var weekDays: [Date] {
        guard let start = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    var body: some View {
        HStack(spacing: 0) {
            Button { shiftWeek(-1) } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 28, height: 44)
            }
            .accessibilityLabel("前の週")

            ForEach(weekDays, id: \.self) { day in
                dayCell(day)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) { selectedDate = day }
                    }
            }

            Button { shiftWeek(1) } label: {
                Image(systemName: "chevron.right")
                    .frame(width: 28, height: 44)
            }
            .accessibilityLabel("次の週")
        }
        .font(.subheadline)
        .padding(.horizontal, 4)
        .gesture(
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    if value.translation.width < -50 { shiftWeek(1) }
                    if value.translation.width > 50 { shiftWeek(-1) }
                }
        )
    }

    private func dayCell(_ day: Date) -> some View {
        let isSelected = calendar.isDate(day, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(day)
        let weekday = calendar.component(.weekday, from: day)
        let symbol = calendar.veryShortWeekdaySymbols[weekday - 1]
        let hasTasks = markedDays.contains(calendar.startOfDay(for: day))

        return VStack(spacing: 6) {
            Text(symbol)
                .font(.caption)
                .foregroundStyle(weekdayColor(weekday))
            Text("\(calendar.component(.day, from: day))")
                .font(.callout.weight(isSelected || isToday ? .bold : .regular))
                .monospacedDigit()
                .frame(width: 36, height: 36)
                .foregroundStyle(isSelected ? Color.white : (isToday ? Color.accentColor : Color.primary))
                .background(Circle().fill(isSelected ? Color.accentColor : Color.clear))
            Circle()
                .fill(hasTasks ? Color.accentColor.opacity(isSelected ? 1 : 0.5) : Color.clear)
                .frame(width: 5, height: 5)
        }
        .padding(.vertical, 4)
    }

    private func weekdayColor(_ weekday: Int) -> Color {
        switch weekday {
        case 1: return Color.red.opacity(0.8)
        case 7: return Color.blue.opacity(0.8)
        default: return Color.secondary
        }
    }

    private func shiftWeek(_ amount: Int) {
        if let date = calendar.date(byAdding: .day, value: 7 * amount, to: selectedDate) {
            withAnimation(.easeInOut(duration: 0.2)) { selectedDate = date }
        }
    }
}

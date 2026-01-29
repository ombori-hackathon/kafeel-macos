import SwiftUI
import KafeelCore

/// 7-column week overview showing meeting load per day
struct WeekOverviewView: View {
    let events: [CalendarEvent]
    let weekStart: Date

    private let calendar = Calendar.current

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Week Overview")
                .font(.headline)

            HStack(spacing: 12) {
                ForEach(0..<7, id: \.self) { dayOffset in
                    if let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) {
                        DayColumn(
                            date: date,
                            events: eventsForDay(date),
                            isToday: calendar.isDateInToday(date)
                        )
                    }
                }
            }

            // Summary row
            WeekSummary(events: events, weekStart: weekStart)
        }
        .padding()
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func eventsForDay(_ date: Date) -> [CalendarEvent] {
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay

        return events.filter { event in
            !event.isAllDay && event.overlaps(start: startOfDay, end: endOfDay)
        }
    }
}

/// Single day column in week view
private struct DayColumn: View {
    let date: Date
    let events: [CalendarEvent]
    let isToday: Bool

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 8) {
            // Day header
            VStack(spacing: 4) {
                Text(dayName)
                    .font(.caption2.bold())
                    .foregroundStyle(isToday ? .white : .secondary)

                Text("\(dayNumber)")
                    .font(.caption.bold())
                    .foregroundStyle(isToday ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isToday ? Color.accentColor : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Events container
            VStack(spacing: 4) {
                ForEach(events.prefix(5)) { event in
                    EventPill(event: event)
                }

                if events.count > 5 {
                    Text("+\(events.count - 5)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 2)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 150, alignment: .top)

            // Meeting load indicator
            MeetingLoadIndicator(meetingMinutes: totalMeetingMinutes)
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }

    private var dayNumber: Int {
        calendar.component(.day, from: date)
    }

    private var totalMeetingMinutes: Int {
        Int(events.reduce(0) { $0 + $1.duration } / 60)
    }
}

/// Small event pill in week view
private struct EventPill: View {
    let event: CalendarEvent

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(event.calendarColor)
                .frame(width: 4, height: 4)

            Text(event.title)
                .font(.caption2)
                .lineLimit(1)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(event.calendarColor.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

/// Visual indicator of meeting load for a day
private struct MeetingLoadIndicator: View {
    let meetingMinutes: Int

    private var loadLevel: (color: Color, intensity: Int) {
        switch meetingMinutes {
        case 0: return (.green, 0)
        case 1..<120: return (.green, 1)
        case 120..<240: return (.yellow, 2)
        case 240..<360: return (.orange, 3)
        default: return (.red, 4)
        }
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<4, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(index < loadLevel.intensity ? loadLevel.color : Color.secondary.opacity(0.2))
                    .frame(height: 3)
            }
        }
    }
}

/// Week summary statistics
private struct WeekSummary: View {
    let events: [CalendarEvent]
    let weekStart: Date

    private var totalMeetings: Int {
        events.filter { !$0.isAllDay }.count
    }

    private var totalMeetingTime: TimeInterval {
        events.filter { !$0.isAllDay }.reduce(0) { $0 + $1.duration }
    }

    private var formattedTotalTime: String {
        let hours = Int(totalMeetingTime) / 3600
        let minutes = (Int(totalMeetingTime) % 3600) / 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }

    var body: some View {
        Divider()

        HStack(spacing: 24) {
            Label("\(totalMeetings) meetings", systemImage: "calendar")
            Label(formattedTotalTime, systemImage: "clock")
            Spacer()
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}

#Preview {
    let calendar = Calendar.current
    let now = Date()
    var weekStart = now
    var interval: TimeInterval = 0
    _ = calendar.dateInterval(of: .weekOfYear, start: &weekStart, interval: &interval, for: now)

    let events = [
        CalendarEvent(
            id: "1",
            title: "Team Standup",
            startDate: calendar.date(byAdding: .hour, value: 9, to: weekStart)!,
            endDate: calendar.date(byAdding: .minute, value: 30, to: calendar.date(byAdding: .hour, value: 9, to: weekStart)!)!,
            calendarColor: .blue
        ),
        CalendarEvent(
            id: "2",
            title: "Planning",
            startDate: calendar.date(byAdding: .hour, value: 35, to: weekStart)!,
            endDate: calendar.date(byAdding: .hour, value: 36, to: weekStart)!,
            calendarColor: .orange
        ),
        CalendarEvent(
            id: "3",
            title: "1:1",
            startDate: calendar.date(byAdding: .hour, value: 62, to: weekStart)!,
            endDate: calendar.date(byAdding: .minute, value: 30, to: calendar.date(byAdding: .hour, value: 62, to: weekStart)!)!,
            calendarColor: .green
        )
    ]

    return WeekOverviewView(events: events, weekStart: weekStart)
        .padding()
        .frame(width: 900)
}

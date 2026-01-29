import SwiftUI
import KafeelCore

/// Hour-by-hour schedule view showing calendar events
struct DayScheduleView: View {
    let events: [CalendarEvent]
    let date: Date

    // Work hours: 6 AM - 10 PM
    private let startHour = 6
    private let endHour = 22
    private let hourHeight: CGFloat = 60

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daily Schedule")
                .font(.headline)

            ScrollView {
                ZStack(alignment: .topLeading) {
                    // Hour grid
                    VStack(spacing: 0) {
                        ForEach(startHour..<endHour, id: \.self) { hour in
                            HourRow(hour: hour, height: hourHeight)
                        }
                    }

                    // Event blocks
                    ForEach(events.filter { !$0.isAllDay }) { event in
                        EventBlock(event: event, startHour: startHour, hourHeight: hourHeight)
                    }
                }
            }
            .frame(height: 500)

            // All-day events
            if !allDayEvents.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("All Day")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ForEach(allDayEvents) { event in
                        HStack {
                            Circle()
                                .fill(event.calendarColor)
                                .frame(width: 8, height: 8)
                            Text(event.title)
                                .font(.callout)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var allDayEvents: [CalendarEvent] {
        events.filter { $0.isAllDay }
    }
}

/// Single hour row in the schedule
private struct HourRow: View {
    let hour: Int
    let height: CGFloat

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Hour label
            Text(formatHour(hour))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .trailing)

            // Divider line
            Rectangle()
                .fill(Color.secondary.opacity(0.2))
                .frame(height: 1)
                .frame(maxWidth: .infinity)
        }
        .frame(height: height)
    }

    private func formatHour(_ hour: Int) -> String {
        let period = hour >= 12 ? "PM" : "AM"
        let displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)
        return "\(displayHour):00 \(period)"
    }
}

/// Event block positioned in the schedule
private struct EventBlock: View {
    let event: CalendarEvent
    let startHour: Int
    let hourHeight: CGFloat

    // Left margin for hour labels
    private let leftMargin: CGFloat = 72

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(event.title)
                .font(.caption.bold())
                .lineLimit(2)

            if let location = event.location {
                Label(location, systemImage: "location.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Text(event.formattedTime)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(event.calendarColor.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(event.calendarColor, lineWidth: 2)
        )
        .offset(x: leftMargin, y: calculateOffset())
        .frame(height: calculateHeight())
    }

    private func calculateOffset() -> CGFloat {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: event.startDate)
        let minute = calendar.component(.minute, from: event.startDate)

        let hoursFromStart = Double(hour - startHour)
        let minuteFraction = Double(minute) / 60.0

        return CGFloat(hoursFromStart + minuteFraction) * hourHeight
    }

    private func calculateHeight() -> CGFloat {
        let durationInHours = event.duration / 3600.0
        return max(30, CGFloat(durationInHours) * hourHeight) // Minimum 30pt height
    }
}

#Preview {
    let calendar = Calendar.current
    let now = Date()
    let startOfDay = calendar.startOfDay(for: now)

    let events = [
        CalendarEvent(
            id: "1",
            title: "Team Standup",
            startDate: calendar.date(byAdding: .hour, value: 9, to: startOfDay)!,
            endDate: calendar.date(byAdding: .minute, value: 30, to: calendar.date(byAdding: .hour, value: 9, to: startOfDay)!)!,
            calendarColor: .blue
        ),
        CalendarEvent(
            id: "2",
            title: "Project Planning Meeting",
            startDate: calendar.date(byAdding: .hour, value: 11, to: startOfDay)!,
            endDate: calendar.date(byAdding: .hour, value: 12, to: startOfDay)!,
            calendarColor: .orange,
            location: "Conference Room A"
        ),
        CalendarEvent(
            id: "3",
            title: "1:1 with Manager",
            startDate: calendar.date(byAdding: .hour, value: 14, to: startOfDay)!,
            endDate: calendar.date(byAdding: .minute, value: 30, to: calendar.date(byAdding: .hour, value: 14, to: startOfDay)!)!,
            calendarColor: .green
        ),
        CalendarEvent(
            id: "4",
            title: "All Day Event",
            startDate: startOfDay,
            endDate: calendar.date(byAdding: .day, value: 1, to: startOfDay)!,
            isAllDay: true,
            calendarColor: .purple
        )
    ]

    return DayScheduleView(events: events, date: now)
        .padding()
        .frame(width: 500)
}

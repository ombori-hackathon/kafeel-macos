import SwiftUI
import EventKit
import KafeelCore

/// Main calendar screen with event display and analytics
struct CalendarView: View {
    @State private var hasPermission = false
    @State private var selectedViewMode: ViewMode = .week
    @State private var selectedDate = Date()
    @State private var events: [CalendarEvent] = []
    @State private var stats: MeetingStats?
    @State private var busiestDay: (day: String, duration: TimeInterval)?
    @State private var dailyStats: [(day: String, meetingTime: TimeInterval, focusTime: TimeInterval)] = []

    private let calendar = Calendar.current
    private let calendarService = CalendarService.shared

    enum ViewMode: String, CaseIterable {
        case day = "Day"
        case week = "Week"
        case month = "Month"

        var icon: String {
            switch self {
            case .day: return "calendar.day.timeline.left"
            case .week: return "calendar"
            case .month: return "calendar.circle"
            }
        }
    }

    var body: some View {
        Group {
            if hasPermission {
                mainContent
            } else {
                CalendarPermissionView {
                    hasPermission = true
                    loadData()
                }
            }
        }
        .onAppear {
            checkPermission()
        }
    }

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header with view mode picker
                header

                // Main content based on view mode
                switch selectedViewMode {
                case .day:
                    dayView
                case .week:
                    weekView
                case .month:
                    monthView
                }

                // Statistics section
                if let stats = stats {
                    statisticsSection(stats: stats)
                }
            }
            .padding()
        }
        .navigationTitle("Calendar")
    }

    private var header: some View {
        VStack(spacing: 16) {
            HStack {
                // Date navigation
                Button {
                    navigateDate(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.borderless)

                Spacer()

                VStack(spacing: 4) {
                    Text(formattedDateRange)
                        .font(.title3.bold())
                    Text(formattedSubtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    navigateDate(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.borderless)
            }

            // View mode picker
            Picker("View Mode", selection: $selectedViewMode) {
                ForEach(ViewMode.allCases, id: \.self) { mode in
                    Label(mode.rawValue, systemImage: mode.icon)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedViewMode) { _, _ in
                loadData()
            }

            // Today button
            Button("Today") {
                selectedDate = Date()
                loadData()
            }
            .buttonStyle(.bordered)
        }
    }

    private var dayView: some View {
        VStack(spacing: 16) {
            DayScheduleView(events: events, date: selectedDate)

            if !events.isEmpty {
                EventList(events: events)
            }
        }
    }

    private var weekView: some View {
        VStack(spacing: 16) {
            WeekOverviewView(events: events, weekStart: weekStart)

            if !dailyStats.isEmpty {
                DailyFocusMeetingChart(dailyStats: dailyStats)
            }
        }
    }

    private var monthView: some View {
        VStack(spacing: 16) {
            Text("Month view coming soon")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 300)
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            EventList(events: events)
        }
    }

    private func statisticsSection(stats: MeetingStats) -> some View {
        VStack(spacing: 16) {
            MeetingStatsCard(stats: stats, busiestDay: busiestDay)

            FocusMeetingChart(stats: stats)
        }
    }

    // MARK: - Date Navigation

    private var formattedDateRange: String {
        let formatter = DateFormatter()

        switch selectedViewMode {
        case .day:
            formatter.dateFormat = "EEEE, MMMM d, yyyy"
            return formatter.string(from: selectedDate)
        case .week:
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
            formatter.dateFormat = "MMM d"
            let startStr = formatter.string(from: weekStart)
            let endStr = formatter.string(from: weekEnd)
            return "\(startStr) - \(endStr)"
        case .month:
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: selectedDate)
        }
    }

    private var formattedSubtitle: String {
        switch selectedViewMode {
        case .day:
            return "\(events.count) events"
        case .week:
            return "Week \(calendar.component(.weekOfYear, from: selectedDate))"
        case .month:
            return "\(events.count) events"
        }
    }

    private var weekStart: Date {
        var start = selectedDate
        var interval: TimeInterval = 0
        calendar.dateInterval(of: .weekOfYear, start: &start, interval: &interval, for: selectedDate)
        return start
    }

    private func navigateDate(by offset: Int) {
        switch selectedViewMode {
        case .day:
            selectedDate = calendar.date(byAdding: .day, value: offset, to: selectedDate) ?? selectedDate
        case .week:
            selectedDate = calendar.date(byAdding: .weekOfYear, value: offset, to: selectedDate) ?? selectedDate
        case .month:
            selectedDate = calendar.date(byAdding: .month, value: offset, to: selectedDate) ?? selectedDate
        }
        loadData()
    }

    // MARK: - Data Loading

    private func checkPermission() {
        let status = calendarService.authorizationStatus
        print("CalendarView: Checking permission, current status = \(status)")

        if status == .fullAccess {
            print("CalendarView: Already have full access")
            hasPermission = true
            loadData()
        } else if status == .notDetermined {
            print("CalendarView: Status is notDetermined, auto-requesting access")
            Task { @MainActor in
                hasPermission = await calendarService.requestAccess()
                print("CalendarView: Auto-request result = \(hasPermission)")
                if hasPermission {
                    loadData()
                }
            }
        } else {
            print("CalendarView: Status is \(status), showing permission view")
        }
    }

    private func loadData() {
        let (start, end) = dateRange

        events = calendarService.fetchEvents(from: start, to: end)
        stats = calendarService.getMeetingStats(from: start, to: end)
        busiestDay = calendarService.getBusiestDay(from: start, to: end)

        // Load daily stats for week view
        if selectedViewMode == .week {
            loadDailyStats()
        }
    }

    private var dateRange: (start: Date, end: Date) {
        switch selectedViewMode {
        case .day:
            let start = calendar.startOfDay(for: selectedDate)
            let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
            return (start, end)
        case .week:
            let start = weekStart
            let end = calendar.date(byAdding: .day, value: 7, to: start) ?? start
            return (start, end)
        case .month:
            var start = selectedDate
            var interval: TimeInterval = 0
            calendar.dateInterval(of: .month, start: &start, interval: &interval, for: selectedDate)
            let end = start.addingTimeInterval(interval)
            return (start, end)
        }
    }

    private func loadDailyStats() {
        let start = weekStart
        let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

        dailyStats = (0..<7).compactMap { dayOffset in
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: start) else {
                return nil
            }

            let meetingTime = calendarService.getMeetingTime(for: date)
            let focusTime = calendarService.getFocusTime(for: date)

            return (dayNames[dayOffset], meetingTime, focusTime)
        }
    }
}

/// List of calendar events
private struct EventList: View {
    let events: [CalendarEvent]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Events")
                .font(.headline)

            if events.isEmpty {
                Text("No events")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(events) { event in
                    EventRow(event: event)
                }
            }
        }
        .padding()
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

/// Single event row
private struct EventRow: View {
    let event: CalendarEvent

    var body: some View {
        HStack(spacing: 12) {
            // Color indicator
            RoundedRectangle(cornerRadius: 2)
                .fill(event.calendarColor)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.callout.bold())

                HStack(spacing: 12) {
                    Label(event.formattedTime, systemImage: "clock")

                    if let location = event.location {
                        Label(location, systemImage: "location")
                    }

                    Spacer()

                    Text(event.formattedDuration)
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    CalendarView()
        .frame(width: 1000, height: 800)
}

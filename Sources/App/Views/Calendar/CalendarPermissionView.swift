import SwiftUI
import KafeelCore

/// View shown when calendar permission is not granted
struct CalendarPermissionView: View {
    @State private var isRequesting = false
    @State private var isDenied = false
    let onPermissionGranted: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: isDenied ? "calendar.badge.exclamationmark" : "calendar.badge.clock")
                .font(.system(size: 64))
                .foregroundStyle(isDenied ? .red : .secondary)

            VStack(spacing: 12) {
                Text(isDenied ? "Calendar Access Denied" : "Calendar Access Required")
                    .font(.title2.bold())

                Text(isDenied
                    ? "You previously denied calendar access. Please enable it in System Settings to view your calendar data."
                    : "Kafeel needs access to your calendar to show meeting times and calculate focus time.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }

            VStack(spacing: 12) {
                if !isDenied {
                    Button {
                        requestPermission()
                    } label: {
                        HStack {
                            if isRequesting {
                                ProgressView()
                                    .controlSize(.small)
                            }
                            Text(isRequesting ? "Requesting Access..." : "Grant Calendar Access")
                        }
                        .frame(minWidth: 200)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isRequesting)
                }

                if isDenied {
                    Button("Open System Settings") {
                        openSystemSettings()
                    }
                    .buttonStyle(BorderedProminentButtonStyle())
                } else {
                    Button("Open System Settings (if needed)") {
                        openSystemSettings()
                    }
                    .buttonStyle(LinkButtonStyle())
                }
            }

            Divider()
                .padding(.vertical)

            VStack(alignment: .leading, spacing: 8) {
                Label("View your meetings and events", systemImage: "calendar")
                Label("Calculate focus time vs meeting time", systemImage: "chart.bar")
                Label("Optimize your schedule", systemImage: "clock.arrow.circlepath")
            }
            .font(.callout)
            .foregroundStyle(.secondary)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func requestPermission() {
        print("CalendarPermissionView: requestPermission called")
        isRequesting = true

        Task { @MainActor in
            print("CalendarPermissionView: Calling CalendarService.requestAccess()")
            let granted = await CalendarService.shared.requestAccess()

            print("CalendarPermissionView: Request completed, granted = \(granted)")
            isRequesting = false

            if granted {
                print("CalendarPermissionView: Permission granted, calling onPermissionGranted")
                onPermissionGranted()
            } else {
                print("CalendarPermissionView: Permission denied, showing system settings option")
                isDenied = true
            }
        }
    }

    private func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
            NSWorkspace.shared.open(url)
        }
    }
}

#Preview {
    CalendarPermissionView {
        print("Permission granted")
    }
}

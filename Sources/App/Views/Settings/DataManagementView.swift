import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import KafeelCore

struct DataManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var activityLogs: [ActivityLog]
    @Query private var categories: [AppCategory]

    @State private var showExportDialog = false
    @State private var showDeleteConfirmation = false
    @State private var exportMessage = ""
    @State private var showExportResult = false

    var body: some View {
        Form {
            Section("Data Overview") {
                LabeledContent("Activity Logs", value: "\(activityLogs.count)")
                LabeledContent("Tracked Apps", value: "\(categories.count)")
                LabeledContent("Total Duration", value: formatTotalDuration())

                if let oldestLog = activityLogs.min(by: { $0.startTime < $1.startTime }) {
                    LabeledContent("Tracking Since", value: oldestLog.startTime.formatted(date: .abbreviated, time: .omitted))
                }
            }

            Section("Export") {
                Button {
                    showExportDialog = true
                } label: {
                    Label("Export All Data", systemImage: "square.and.arrow.up")
                }
                .disabled(activityLogs.isEmpty)

                Text("Export your activity data as JSON for backup or analysis.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Danger Zone") {
                SecureActionButton(
                    "Delete All Data",
                    systemImage: "trash",
                    role: .destructive,
                    reason: "Authenticate to delete all activity data"
                ) {
                    showDeleteConfirmation = true
                }
                .disabled(activityLogs.isEmpty && categories.isEmpty)

                Text("This will permanently delete all activity logs and app categories. This action cannot be undone.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Data Management")
        .fileExporter(
            isPresented: $showExportDialog,
            document: ActivityDataDocument(
                activityLogs: activityLogs,
                categories: categories
            ),
            contentType: .json,
            defaultFilename: "kafeel-export-\(Date().formatted(date: .numeric, time: .omitted)).json"
        ) { result in
            switch result {
            case .success(let url):
                exportMessage = "Data exported successfully to \(url.lastPathComponent)"
            case .failure(let error):
                exportMessage = "Export failed: \(error.localizedDescription)"
            }
            showExportResult = true
        }
        .confirmationDialog(
            "Delete All Data",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Everything", role: .destructive) {
                deleteAllData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete \(activityLogs.count) activity logs and \(categories.count) app categories. This cannot be undone.")
        }
        .alert("Export Result", isPresented: $showExportResult) {
            Button("OK") {}
        } message: {
            Text(exportMessage)
        }
    }

    private func formatTotalDuration() -> String {
        let totalSeconds = activityLogs.reduce(0) { $0 + $1.durationSeconds }
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    private func deleteAllData() {
        // Delete all activity logs
        for log in activityLogs {
            modelContext.delete(log)
        }

        // Delete all categories (except defaults)
        for category in categories where !category.isDefault {
            modelContext.delete(category)
        }

        do {
            try modelContext.save()
        } catch {
            print("Failed to delete data: \(error)")
        }
    }
}

// Document type for exporting data
struct ActivityDataDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    let activityLogs: [ActivityLog]
    let categories: [AppCategory]

    init(activityLogs: [ActivityLog], categories: [AppCategory]) {
        self.activityLogs = activityLogs
        self.categories = categories
    }

    init(configuration: ReadConfiguration) throws {
        // Not implementing read as we only export
        self.activityLogs = []
        self.categories = []
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let exportData = ExportData(
            exportDate: Date(),
            activityLogs: activityLogs.map(ActivityLogExport.init),
            categories: categories.map(AppCategoryExport.init)
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(exportData)
        return FileWrapper(regularFileWithContents: data)
    }
}

struct ExportData: Codable {
    let exportDate: Date
    let activityLogs: [ActivityLogExport]
    let categories: [AppCategoryExport]
}

struct ActivityLogExport: Codable {
    let id: UUID
    let appBundleIdentifier: String
    let appName: String
    let windowTitle: String?
    let startTime: Date
    let endTime: Date?
    let durationSeconds: Int

    init(from log: ActivityLog) {
        self.id = log.id
        self.appBundleIdentifier = log.appBundleIdentifier
        self.appName = log.appName
        self.windowTitle = log.windowTitle
        self.startTime = log.startTime
        self.endTime = log.endTime
        self.durationSeconds = log.durationSeconds
    }
}

struct AppCategoryExport: Codable {
    let bundleIdentifier: String
    let appName: String
    let category: String
    let isDefault: Bool
    let lastModified: Date

    init(from category: AppCategory) {
        self.bundleIdentifier = category.bundleIdentifier
        self.appName = category.appName
        self.category = category.category.rawValue
        self.isDefault = category.isDefault
        self.lastModified = category.lastModified
    }
}

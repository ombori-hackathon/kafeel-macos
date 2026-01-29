import SwiftUI
import SwiftData
import KafeelCore

struct CategoryManagerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AppCategory.lastModified, order: .reverse) private var categories: [AppCategory]
    @Query private var activityLogs: [ActivityLog]

    @State private var searchText = ""
    @State private var groupByCategory = false
    @State private var selectedCategory: AppCategory?
    @State private var showCategoryPicker = false

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                TextField("Search apps...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 300)

                Spacer()

                Toggle("Group by Category", isOn: $groupByCategory)
                    .toggleStyle(.switch)
            }
            .padding()

            Divider()

            // Content
            if groupByCategory {
                groupedView
            } else {
                listView
            }
        }
        .navigationTitle("Category Manager")
        .sheet(isPresented: $showCategoryPicker) {
            if let selected = selectedCategory {
                CategoryPickerSheet(category: selected)
            }
        }
    }

    private var filteredCategories: [AppCategory] {
        if searchText.isEmpty {
            return categories
        }
        return categories.filter {
            $0.appName.localizedCaseInsensitiveContains(searchText) ||
            $0.bundleIdentifier.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var listView: some View {
        List(filteredCategories) { category in
            CategoryRow(
                category: category,
                lastUsed: lastUsedDate(for: category)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                selectedCategory = category
                showCategoryPicker = true
            }
        }
    }

    private var groupedView: some View {
        List {
            ForEach(CategoryType.allCases, id: \.self) { categoryType in
                let items = filteredCategories.filter { $0.category == categoryType }
                if !items.isEmpty {
                    Section {
                        ForEach(items) { category in
                            CategoryRow(
                                category: category,
                                lastUsed: lastUsedDate(for: category),
                                showCategoryBadge: false
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedCategory = category
                                showCategoryPicker = true
                            }
                        }
                    } header: {
                        HStack {
                            Circle()
                                .fill(categoryType.color)
                                .frame(width: 12, height: 12)
                            Text(categoryType.displayName)
                        }
                    }
                }
            }
        }
    }

    private func lastUsedDate(for category: AppCategory) -> Date? {
        activityLogs
            .filter { $0.appBundleIdentifier == category.bundleIdentifier }
            .max(by: { $0.startTime < $1.startTime })?.startTime
    }
}

struct CategoryRow: View {
    let category: AppCategory
    let lastUsed: Date?
    var showCategoryBadge: Bool = true

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(category.appName)
                    .font(.headline)

                Text(category.bundleIdentifier)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let lastUsed {
                    Text("Last used: \(lastUsed.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                } else {
                    Text("Never used")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            if showCategoryBadge {
                CategoryBadge(category: category.category)
            }
        }
        .padding(.vertical, 4)
    }
}

struct CategoryBadge: View {
    let category: CategoryType

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(category.color)
                .frame(width: 10, height: 10)
            Text(category.displayName)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(category.color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct CategoryPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let category: AppCategory

    @State private var selectedCategoryType: CategoryType
    @State private var isAuthenticating = false

    init(category: AppCategory) {
        self.category = category
        self._selectedCategoryType = State(initialValue: category.category)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(category.appName)
                        .font(.headline)
                    Text(category.bundleIdentifier)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Select Category") {
                    Picker("Category", selection: $selectedCategoryType) {
                        ForEach(CategoryType.allCases, id: \.self) { type in
                            HStack {
                                Circle()
                                    .fill(type.color)
                                    .frame(width: 12, height: 12)
                                Text(type.displayName)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
            }
            .navigationTitle("Change Category")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    SecureActionButton(
                        "Save",
                        reason: "Authenticate to change app category"
                    ) {
                        category.updateCategory(selectedCategoryType)
                        dismiss()
                    }
                    .disabled(selectedCategoryType == category.category)
                }
            }
        }
        .frame(width: 400, height: 500)
    }
}

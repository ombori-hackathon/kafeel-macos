import Foundation
import SwiftData

@MainActor
public final class PersistenceService {
    public static let shared = PersistenceService()

    let container: ModelContainer
    let context: ModelContext

    private init() {
        let schema = Schema([
            ActivityLog.self,
            AppCategory.self,
            AppSettings.self,
            // Flow Score models
            DailyScore.self,
            Streak.self,
            Achievement.self,
            PersonalRecord.self,
            UserProfile.self,
            MeetingSession.self
        ])

        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            context = ModelContext(container)

            // Initialize default categories on first run
            try initializeDefaultCategories()
            // Initialize Flow Score data on first run
            try initializeFlowScoreData()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    // MARK: - Activity Log Operations

    func saveActivityLog(_ log: ActivityLog) throws {
        context.insert(log)
        try context.save()
    }

    func fetchActivities(for date: Date) throws -> [ActivityLog] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }

        let predicate = #Predicate<ActivityLog> { log in
            log.startTime >= startOfDay && log.startTime < endOfDay
        }

        let descriptor = FetchDescriptor<ActivityLog>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.startTime, order: .forward)]
        )

        return try context.fetch(descriptor)
    }

    func fetchActivities(from startDate: Date, to endDate: Date) throws -> [ActivityLog] {
        let predicate = #Predicate<ActivityLog> { log in
            log.startTime >= startDate && log.startTime < endDate
        }

        let descriptor = FetchDescriptor<ActivityLog>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.startTime, order: .forward)]
        )

        return try context.fetch(descriptor)
    }

    // MARK: - Category Operations

    func getCategory(for bundleIdentifier: String) -> AppCategory? {
        let predicate = #Predicate<AppCategory> { category in
            category.bundleIdentifier == bundleIdentifier
        }

        let descriptor = FetchDescriptor<AppCategory>(predicate: predicate)

        return try? context.fetch(descriptor).first
    }

    func setCategory(_ category: CategoryType, for bundleIdentifier: String, appName: String) throws {
        if let existing = getCategory(for: bundleIdentifier) {
            existing.updateCategory(category)
        } else {
            let newCategory = AppCategory(
                bundleIdentifier: bundleIdentifier,
                appName: appName,
                category: category,
                isDefault: false
            )
            context.insert(newCategory)
        }
        try context.save()
    }

    // MARK: - Settings Operations

    func getOrCreateSettings() throws -> AppSettings {
        let descriptor = FetchDescriptor<AppSettings>()
        let allSettings = try context.fetch(descriptor)

        if let existing = allSettings.first {
            return existing
        }

        let newSettings = AppSettings()
        context.insert(newSettings)
        try context.save()
        return newSettings
    }

    // MARK: - Utility Operations

    func deleteAllData() async throws {
        try context.delete(model: ActivityLog.self)
        try context.delete(model: AppCategory.self)
        try context.delete(model: AppSettings.self)
        try context.delete(model: DailyScore.self)
        try context.delete(model: Streak.self)
        try context.delete(model: Achievement.self)
        try context.delete(model: PersonalRecord.self)
        try context.delete(model: UserProfile.self)
        try context.delete(model: MeetingSession.self)
        try context.save()
    }

    // MARK: - User Profile Operations

    public func getOrCreateUserProfile() throws -> UserProfile {
        let descriptor = FetchDescriptor<UserProfile>()
        let profiles = try context.fetch(descriptor)

        if let existing = profiles.first {
            return existing
        }

        let newProfile = UserProfile()
        context.insert(newProfile)
        try context.save()
        return newProfile
    }

    // MARK: - Streak Operations

    public func getOrCreateStreak() throws -> Streak {
        let descriptor = FetchDescriptor<Streak>()
        let streaks = try context.fetch(descriptor)

        if let existing = streaks.first {
            return existing
        }

        let newStreak = Streak()
        context.insert(newStreak)
        try context.save()
        return newStreak
    }

    // MARK: - Daily Score Operations

    public func getDailyScore(for date: Date) throws -> DailyScore? {
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)

        let predicate = #Predicate<DailyScore> { score in
            score.date == targetDate
        }

        let descriptor = FetchDescriptor<DailyScore>(predicate: predicate)
        return try context.fetch(descriptor).first
    }

    public func getOrCreateDailyScore(for date: Date) throws -> DailyScore {
        if let existing = try getDailyScore(for: date) {
            return existing
        }

        let newScore = DailyScore(date: date)
        context.insert(newScore)
        try context.save()
        return newScore
    }

    public func fetchDailyScores(from startDate: Date, to endDate: Date) throws -> [DailyScore] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)

        let predicate = #Predicate<DailyScore> { score in
            score.date >= start && score.date <= end
        }

        let descriptor = FetchDescriptor<DailyScore>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )

        return try context.fetch(descriptor)
    }

    // MARK: - Achievement Operations

    public func getAchievement(type: AchievementType) throws -> Achievement? {
        let typeRaw = type.rawValue
        let predicate = #Predicate<Achievement> { achievement in
            achievement.typeRawValue == typeRaw
        }

        let descriptor = FetchDescriptor<Achievement>(predicate: predicate)
        return try context.fetch(descriptor).first
    }

    public func getOrCreateAchievement(type: AchievementType) throws -> Achievement {
        if let existing = try getAchievement(type: type) {
            return existing
        }

        let newAchievement = Achievement(type: type)
        context.insert(newAchievement)
        try context.save()
        return newAchievement
    }

    public func getAllAchievements() throws -> [Achievement] {
        let descriptor = FetchDescriptor<Achievement>()
        let achievements = try context.fetch(descriptor)
        // Sort unlocked first, then by type
        return achievements.sorted { $0.isUnlocked && !$1.isUnlocked }
    }

    public func getUnlockedAchievements() throws -> [Achievement] {
        let predicate = #Predicate<Achievement> { achievement in
            achievement.isUnlocked
        }

        let descriptor = FetchDescriptor<Achievement>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.unlockedAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    // MARK: - Personal Record Operations

    public func getRecord(category: RecordCategory) throws -> PersonalRecord? {
        let categoryRaw = category.rawValue
        let predicate = #Predicate<PersonalRecord> { record in
            record.categoryRawValue == categoryRaw
        }

        let descriptor = FetchDescriptor<PersonalRecord>(predicate: predicate)
        return try context.fetch(descriptor).first
    }

    public func getOrCreateRecord(category: RecordCategory) throws -> PersonalRecord {
        if let existing = try getRecord(category: category) {
            return existing
        }

        let newRecord = PersonalRecord(category: category)
        context.insert(newRecord)
        try context.save()
        return newRecord
    }

    public func getAllRecords() throws -> [PersonalRecord] {
        let descriptor = FetchDescriptor<PersonalRecord>()
        return try context.fetch(descriptor)
    }

    // MARK: - Meeting Session Operations

    public func saveMeetingSession(_ session: MeetingSession) throws {
        context.insert(session)
        try context.save()
    }

    public func getActiveMeetingSessions() throws -> [MeetingSession] {
        let predicate = #Predicate<MeetingSession> { session in
            session.isActive
        }

        let descriptor = FetchDescriptor<MeetingSession>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    public func getMeetingSessions(for date: Date) throws -> [MeetingSession] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }

        let predicate = #Predicate<MeetingSession> { session in
            session.startTime >= startOfDay && session.startTime < endOfDay
        }

        let descriptor = FetchDescriptor<MeetingSession>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.startTime, order: .forward)]
        )
        return try context.fetch(descriptor)
    }

    public func getTotalMeetingSeconds(for date: Date) throws -> Int {
        let sessions = try getMeetingSessions(for: date)
        return sessions.reduce(0) { $0 + $1.durationSeconds }
    }

    // MARK: - Save Context

    public func save() throws {
        try context.save()
    }

    // MARK: - Private Helpers

    private func initializeDefaultCategories() throws {
        // Check if we already have categories
        let descriptor = FetchDescriptor<AppCategory>()
        let existingCategories = try context.fetch(descriptor)

        guard existingCategories.isEmpty else {
            return // Already initialized
        }

        // Add all default categories
        for (bundleId, info) in DefaultCategories.mappings {
            let category = AppCategory(
                bundleIdentifier: bundleId,
                appName: info.name,
                category: info.category,
                isDefault: true
            )
            context.insert(category)
        }

        try context.save()
        print("Initialized \(DefaultCategories.mappings.count) default app categories")
    }

    private func initializeFlowScoreData() throws {
        // Initialize User Profile
        let profileDescriptor = FetchDescriptor<UserProfile>()
        if try context.fetch(profileDescriptor).isEmpty {
            let profile = UserProfile()
            context.insert(profile)
        }

        // Initialize Streak
        let streakDescriptor = FetchDescriptor<Streak>()
        if try context.fetch(streakDescriptor).isEmpty {
            let streak = Streak()
            context.insert(streak)
        }

        // Initialize Achievements for all types
        let achievementDescriptor = FetchDescriptor<Achievement>()
        let existingAchievements = try context.fetch(achievementDescriptor)
        let existingTypes = Set(existingAchievements.map { $0.typeRawValue })

        for type in AchievementType.allCases {
            if !existingTypes.contains(type.rawValue) {
                let achievement = Achievement(type: type)
                context.insert(achievement)
            }
        }

        // Initialize Personal Records for all categories
        let recordDescriptor = FetchDescriptor<PersonalRecord>()
        let existingRecords = try context.fetch(recordDescriptor)
        let existingCategories = Set(existingRecords.map { $0.categoryRawValue })

        for category in RecordCategory.allCases {
            if !existingCategories.contains(category.rawValue) {
                let record = PersonalRecord(category: category)
                context.insert(record)
            }
        }

        try context.save()
        print("Initialized Flow Score data (profile, streak, achievements, records)")
    }
}

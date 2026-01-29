import Foundation
import SwiftData

@Model
public final class AppCategory {
    @Attribute(.unique) public var bundleIdentifier: String
    public var appName: String
    public var category: CategoryType
    public var isDefault: Bool
    public var lastModified: Date

    public init(
        bundleIdentifier: String,
        appName: String,
        category: CategoryType,
        isDefault: Bool = false
    ) {
        self.bundleIdentifier = bundleIdentifier
        self.appName = appName
        self.category = category
        self.isDefault = isDefault
        self.lastModified = Date()
    }

    public func updateCategory(_ newCategory: CategoryType) {
        self.category = newCategory
        self.isDefault = false
        self.lastModified = Date()
    }
}

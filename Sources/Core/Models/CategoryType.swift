import SwiftUI

public enum CategoryType: String, Codable, CaseIterable, Sendable {
    case productive
    case distracting
    case neutral

    public var displayName: String {
        rawValue.capitalized
    }

    public var color: Color {
        switch self {
        case .productive: return .green
        case .distracting: return .red
        case .neutral: return .gray
        }
    }

    public var weight: Double {
        switch self {
        case .productive: return 1.0
        case .neutral: return 0.5
        case .distracting: return 0.0
        }
    }
}

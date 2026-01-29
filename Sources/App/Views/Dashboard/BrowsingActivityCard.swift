import SwiftUI

struct BrowsingActivityCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "safari.fill")
                    .foregroundStyle(.blue)
                Text("Browsing Activity")
                    .font(.headline)
                Spacer()
            }

            VStack(spacing: 12) {
                Image(systemName: "globe")
                    .font(.system(size: 32))
                    .foregroundStyle(.secondary)

                Text("Coming Soon")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.primary)

                Text("Browser history tracking will be available in a future update")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous)
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }
}

#Preview {
    BrowsingActivityCard()
        .padding()
        .frame(width: 400)
}

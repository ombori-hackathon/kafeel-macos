import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            // App Icon
            AppIconView(size: 128)
                .frame(width: 128, height: 128)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)

            // App Name
            Text("Kafeel")
                .font(.system(size: 32, weight: .bold))

            // Tagline
            Text("Activity Tracker")
                .font(.headline)
                .foregroundStyle(.secondary)

            Divider()
                .padding(.horizontal, 40)

            // Version Info
            VStack(spacing: 8) {
                Text("Version 1.0.0")
                    .font(.subheadline)

                Text("Built with Swift & SwiftUI")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
                .frame(height: 20)

            // Close button
            Button("Close") {
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding(30)
        .frame(width: 400, height: 500)
    }
}

#Preview {
    AboutView()
}

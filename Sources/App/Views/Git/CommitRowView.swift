import SwiftUI
import KafeelCore

struct CommitRowView: View {
    let commit: GitActivity

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Commit indicator
            Circle()
                .fill(.blue)
                .frame(width: 8, height: 8)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 6) {
                // Message and hash
                HStack(alignment: .firstTextBaseline) {
                    Text(commit.message)
                        .font(.headline)
                        .lineLimit(2)

                    Spacer()

                    Text(commit.shortHash)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.quaternary)
                        .cornerRadius(4)
                }

                // Metadata
                HStack {
                    Label(commit.author, systemImage: "person.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("•")
                        .foregroundStyle(.tertiary)

                    Label(commit.timeAgo, systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("•")
                        .foregroundStyle(.tertiary)

                    Label(commit.repositoryName, systemImage: "folder")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    // Stats
                    if commit.additions > 0 || commit.deletions > 0 {
                        HStack(spacing: 8) {
                            if commit.additions > 0 {
                                HStack(spacing: 2) {
                                    Text("+\(commit.additions)")
                                        .font(.caption.bold())
                                        .foregroundStyle(.green)
                                }
                            }
                            if commit.deletions > 0 {
                                HStack(spacing: 2) {
                                    Text("-\(commit.deletions)")
                                        .font(.caption.bold())
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(.background.secondary)
        .cornerRadius(8)
    }
}

#Preview {
    CommitRowView(commit: GitActivity(
        commitHash: "a1b2c3d4e5f6",
        message: "Add new feature for tracking Git commits with detailed statistics",
        author: "John Doe",
        date: Date().addingTimeInterval(-3600),
        repositoryPath: "/Users/john/workspace/kafeel",
        repositoryName: "kafeel",
        additions: 245,
        deletions: 18,
        filesChanged: 12
    ))
    .padding()
}

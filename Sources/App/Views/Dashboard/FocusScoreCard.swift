import SwiftUI

struct FocusScoreCard: View {
    let score: Double
    @State private var animatedScore: Double = 0

    private var scoreColor: Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .blue
        case 40..<60: return .yellow
        case 20..<40: return .orange
        default: return .red
        }
    }

    private var scoreGradient: LinearGradient {
        switch score {
        case 80...100: return LinearGradient(
            colors: [Color.green, Color.mint],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        case 60..<80: return LinearGradient(
            colors: [Color.blue, Color.cyan],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        case 40..<60: return LinearGradient(
            colors: [Color.yellow, Color.orange],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        case 20..<40: return LinearGradient(
            colors: [Color.orange, Color.red],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        default: return LinearGradient(
            colors: [Color.red, Color.pink],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        }
    }

    private var scoreLabel: String {
        switch score {
        case 80...100: return "Excellent"
        case 60..<80: return "Good"
        case 40..<60: return "Fair"
        case 20..<40: return "Needs Improvement"
        default: return "Low Focus"
        }
    }

    private var scoreEmoji: String {
        switch score {
        case 80...100: return "🎯"
        case 60..<80: return "👍"
        case 40..<60: return "📊"
        case 20..<40: return "⚠️"
        default: return "🔴"
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("Today's Focus Score")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)

            ZStack {
                // Background circle
                Circle()
                    .stroke(scoreColor.opacity(0.1), lineWidth: 20)
                    .frame(width: 200, height: 200)

                // Animated progress circle
                Circle()
                    .trim(from: 0, to: animatedScore / 100)
                    .stroke(scoreGradient, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 1.0, dampingFraction: 0.7), value: animatedScore)

                // Center content
                VStack(spacing: 8) {
                    Text("\(Int(animatedScore))")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundStyle(scoreColor)
                        .contentTransition(.numericText(value: animatedScore))

                    Text(scoreLabel)
                        .font(.body.weight(.medium))
                        .foregroundStyle(scoreColor)
                }
            }

            Text("Based on app usage patterns and focus sessions")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(
            ZStack {
                // Gradient background
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous)
                    .fill(scoreColor.opacity(0.05))

                // Glass morphism overlay
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous)
                    .fill(.ultraThinMaterial)
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous)
                .strokeBorder(scoreColor.opacity(0.2), lineWidth: 1.5)
        )
        .shadow(
            color: scoreColor.opacity(0.15),
            radius: 20,
            y: 10
        )
        .onAppear {
            withAnimation(.spring(response: 1.2, dampingFraction: 0.7).delay(0.2)) {
                animatedScore = score
            }
        }
        .onChange(of: score) { _, newValue in
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                animatedScore = newValue
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        FocusScoreCard(score: 85)
        FocusScoreCard(score: 65)
        FocusScoreCard(score: 45)
        FocusScoreCard(score: 25)
        FocusScoreCard(score: 10)
    }
    .padding()
    .frame(width: 400)
}

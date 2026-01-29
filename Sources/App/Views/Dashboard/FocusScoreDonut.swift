import SwiftUI

struct FocusScoreDonut: View {
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
        case 20..<40: return "Needs Work"
        default: return "Low"
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("Focus Score")
                .font(.headline)
                .foregroundStyle(.secondary)

            ZStack {
                // Background circle
                Circle()
                    .stroke(scoreColor.opacity(0.15), lineWidth: 12)
                    .frame(width: 120, height: 120)

                // Animated progress circle
                Circle()
                    .trim(from: 0, to: animatedScore / 100)
                    .stroke(scoreGradient, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 1.0, dampingFraction: 0.7), value: animatedScore)

                // Center content
                VStack(spacing: 2) {
                    Text("\(Int(animatedScore))")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(scoreColor)
                        .contentTransition(.numericText(value: animatedScore))

                    Text(scoreLabel)
                        .font(.caption2)
                        .foregroundStyle(scoreColor.opacity(0.8))
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous)
                .strokeBorder(scoreColor.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: scoreColor.opacity(0.1), radius: 10, y: 4)
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
    HStack {
        FocusScoreDonut(score: 85)
        FocusScoreDonut(score: 65)
        FocusScoreDonut(score: 45)
    }
    .padding()
}

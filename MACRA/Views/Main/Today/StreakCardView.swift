import SwiftUI

struct StreakCardView: View {
    let currentStreak: Int
    let longestStreak: Int

    private var progress: Double {
        min(Double(currentStreak) / 30.0, 1.0)
    }

    private var messageTitle: String {
        currentStreak > 0 ? "You've been keeping track" : "Start your streak"
    }

    private var messageBody: String {
        if currentStreak == 0 {
            return "Log your first meal to start building your streak."
        } else if currentStreak == 1 {
            return "You logged an entry today. Keep it going!"
        } else if currentStreak <= 7 {
            return "You've added an entry every day for the past \(currentStreak) days."
        } else {
            return "You've added an entry every day for the past \(currentStreak) days. Incredible consistency!"
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            // Circular progress ring
            ZStack {
                // Track
                Circle()
                    .stroke(Color(.systemGreen).opacity(0.15), lineWidth: 6)

                // Progress
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color(.systemGreen), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)

                // Center content
                VStack(spacing: 0) {
                    Text("\(currentStreak)")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color(.label))

                    Text("Days")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color(.secondaryLabel))

                    Image(systemName: "flame.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(.systemGreen))
                }
            }
            .frame(width: 64, height: 64)

            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(messageTitle)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(.label))

                Text(messageBody)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color(.secondaryLabel))
                    .lineLimit(2)

                HStack(spacing: 4) {
                    Text("Longest streak")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(.secondaryLabel))

                    Text("\(longestStreak) days")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(.systemOrange))
                }
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemGreen).opacity(0.08))
        )
        .padding(.horizontal, 20)
    }
}

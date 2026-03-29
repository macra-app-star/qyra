import SwiftUI

struct DailyStatus {
    let label: String
    let color: Color
    let icon: String

    static func evaluate(
        consumed: Double,
        target: Double,
        protein: Double,
        proteinTarget: Double,
        mealsLogged: Int,
        hour: Int
    ) -> DailyStatus {
        let caloriePercent = consumed / max(target, 1)
        let proteinPercent = protein / max(proteinTarget, 1)

        // Morning — hasn't started yet
        if hour < 10 && mealsLogged == 0 {
            return DailyStatus(label: "Ready to start", color: .secondary, icon: "sunrise")
        }

        // Over target
        if caloriePercent > 1.1 {
            return DailyStatus(label: "Over target", color: .red, icon: "exclamationmark.triangle.fill")
        }

        // Perfect tracking
        if caloriePercent >= 0.85 && caloriePercent <= 1.05 && proteinPercent >= 0.9 {
            return DailyStatus(label: "Dialed", color: .green, icon: "checkmark.seal.fill")
        }

        // On track — middle of day
        if caloriePercent >= 0.4 && caloriePercent <= 0.85 && hour >= 12 && hour <= 20 {
            return DailyStatus(label: "Locked in", color: .blue, icon: "bolt.fill")
        }

        // Protein lagging
        if proteinPercent < 0.5 && caloriePercent > 0.5 {
            return DailyStatus(label: "Protein lagging", color: .orange, icon: "exclamationmark.circle.fill")
        }

        // Behind — evening and not enough consumed
        if hour >= 18 && caloriePercent < 0.5 {
            return DailyStatus(label: "Behind", color: .orange, icon: "clock.arrow.circlepath")
        }

        // Good consistency
        if mealsLogged >= 3 && caloriePercent >= 0.6 {
            return DailyStatus(label: "Consistent", color: .green, icon: "flame.fill")
        }

        // Default
        return DailyStatus(label: "Tracking", color: .secondary, icon: "chart.line.uptrend.xyaxis")
    }
}

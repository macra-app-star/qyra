import SwiftUI

enum BadgeCategory: String, CaseIterable, Identifiable {
    case logging = "Logging"
    case streak = "Streak"
    case nutrition = "Nutrition"
    case weight = "Weight"
    case social = "Social"
    case exercise = "Exercise"
    case mastery = "Mastery"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .logging: return "pencil.and.list.clipboard"
        case .streak: return "flame.fill"
        case .nutrition: return "leaf.fill"
        case .weight: return "scalemass.fill"
        case .social: return "person.2.fill"
        case .exercise: return "figure.run"
        case .mastery: return "trophy.fill"
        }
    }

    var color: Color {
        switch self {
        case .logging: return DesignTokens.Colors.brandAccent
        case .streak: return DesignTokens.Colors.streakOrange
        case .nutrition: return DesignTokens.Colors.protein
        case .weight: return DesignTokens.Colors.fat
        case .social: return DesignTokens.Colors.aiAccent
        case .exercise: return DesignTokens.Colors.exerciseRing
        case .mastery: return DesignTokens.Colors.healthScoreAccent
        }
    }
}

struct Badge: Identifiable, Equatable {
    let id: UUID
    let name: String
    let description: String
    let category: BadgeCategory
    let iconName: String
    var isUnlocked: Bool
    let xpValue: Int

    static func == (lhs: Badge, rhs: Badge) -> Bool {
        lhs.id == rhs.id
    }

    static let allBadges: [Badge] = [
        // Logging (5)
        Badge(id: UUID(), name: "First Log", description: "Log your first meal", category: .logging, iconName: "pencil", isUnlocked: false, xpValue: 10),
        Badge(id: UUID(), name: "Ten Logs", description: "Log 10 meals", category: .logging, iconName: "pencil.and.list.clipboard", isUnlocked: false, xpValue: 25),
        Badge(id: UUID(), name: "50 Club", description: "Log 50 meals", category: .logging, iconName: "star", isUnlocked: false, xpValue: 50),
        Badge(id: UUID(), name: "Century", description: "Log 100 meals", category: .logging, iconName: "star.fill", isUnlocked: false, xpValue: 100),
        Badge(id: UUID(), name: "Dedicated Logger", description: "Log 500 meals", category: .logging, iconName: "crown", isUnlocked: false, xpValue: 250),

        // Streak (5)
        Badge(id: UUID(), name: "Getting Started", description: "3-day streak", category: .streak, iconName: "flame", isUnlocked: false, xpValue: 15),
        Badge(id: UUID(), name: "Week Warrior", description: "7-day streak", category: .streak, iconName: "flame.fill", isUnlocked: false, xpValue: 30),
        Badge(id: UUID(), name: "Two Weeks", description: "14-day streak", category: .streak, iconName: "bolt.fill", isUnlocked: false, xpValue: 50),
        Badge(id: UUID(), name: "Monthly Master", description: "30-day streak", category: .streak, iconName: "bolt.circle.fill", isUnlocked: false, xpValue: 100),
        Badge(id: UUID(), name: "Unstoppable", description: "90-day streak", category: .streak, iconName: "sparkles", isUnlocked: false, xpValue: 500),

        // Nutrition (4)
        Badge(id: UUID(), name: "Protein Pro", description: "Hit protein goal 7 days", category: .nutrition, iconName: "fork.knife", isUnlocked: false, xpValue: 30),
        Badge(id: UUID(), name: "Balanced Eater", description: "Hit all macros in one day", category: .nutrition, iconName: "chart.pie", isUnlocked: false, xpValue: 40),
        Badge(id: UUID(), name: "Fiber Friend", description: "Hit fiber goal 5 days", category: .nutrition, iconName: "leaf", isUnlocked: false, xpValue: 25),
        Badge(id: UUID(), name: "Macro Master", description: "Hit all macros for a week", category: .nutrition, iconName: "trophy", isUnlocked: false, xpValue: 100),

        // Weight (4)
        Badge(id: UUID(), name: "First Weigh-In", description: "Log your first weight", category: .weight, iconName: "scalemass", isUnlocked: false, xpValue: 10),
        Badge(id: UUID(), name: "5 Down", description: "Lose 5 lbs", category: .weight, iconName: "arrow.down.right", isUnlocked: false, xpValue: 50),
        Badge(id: UUID(), name: "10 Down", description: "Lose 10 lbs", category: .weight, iconName: "arrow.down", isUnlocked: false, xpValue: 100),
        Badge(id: UUID(), name: "Goal Reached", description: "Reach your goal weight", category: .weight, iconName: "flag.checkered", isUnlocked: false, xpValue: 500),

        // Social (4)
        Badge(id: UUID(), name: "Joined Up", description: "Join your first group", category: .social, iconName: "person.2", isUnlocked: false, xpValue: 15),
        Badge(id: UUID(), name: "Team Player", description: "Send 10 messages", category: .social, iconName: "bubble.left.fill", isUnlocked: false, xpValue: 25),
        Badge(id: UUID(), name: "Motivator", description: "React to 20 messages", category: .social, iconName: "hand.thumbsup.fill", isUnlocked: false, xpValue: 30),
        Badge(id: UUID(), name: "Community Star", description: "Top 3 on leaderboard", category: .social, iconName: "star.circle.fill", isUnlocked: false, xpValue: 100),

        // Exercise (4)
        Badge(id: UUID(), name: "First Workout", description: "Log your first exercise", category: .exercise, iconName: "figure.walk", isUnlocked: false, xpValue: 10),
        Badge(id: UUID(), name: "Burn 1000", description: "Burn 1000 calories total", category: .exercise, iconName: "flame", isUnlocked: false, xpValue: 50),
        Badge(id: UUID(), name: "Burn 5000", description: "Burn 5000 calories total", category: .exercise, iconName: "flame.fill", isUnlocked: false, xpValue: 100),
        Badge(id: UUID(), name: "Fitness Fanatic", description: "Log 50 exercises", category: .exercise, iconName: "dumbbell.fill", isUnlocked: false, xpValue: 200),

        // Mastery (4)
        Badge(id: UUID(), name: "Explorer", description: "Use all app features", category: .mastery, iconName: "map", isUnlocked: false, xpValue: 50),
        Badge(id: UUID(), name: "Consistent", description: "Use app for 30 days", category: .mastery, iconName: "calendar", isUnlocked: false, xpValue: 100),
        Badge(id: UUID(), name: "Expert", description: "Earn 1000 XP", category: .mastery, iconName: "graduationcap.fill", isUnlocked: false, xpValue: 200),
        Badge(id: UUID(), name: "Legend", description: "Earn all other badges", category: .mastery, iconName: "crown.fill", isUnlocked: false, xpValue: 1000),
    ]
}

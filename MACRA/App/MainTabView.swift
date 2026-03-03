import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .today

    enum Tab: String, CaseIterable {
        case today
        case log
        case insights
        case social
        case settings

        var title: String {
            rawValue.capitalized
        }

        var icon: String {
            switch self {
            case .today: return "chart.bar.fill"
            case .log: return "plus.circle.fill"
            case .insights: return "chart.line.uptrend.xyaxis"
            case .social: return "person.2.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(Tab.allCases, id: \.self) { tab in
                NavigationStack {
                    tabContent(for: tab)
                }
                .tabItem {
                    Label(tab.title, systemImage: tab.icon)
                }
                .tag(tab)
            }
        }
        .tint(DesignTokens.Colors.accent)
    }

    @ViewBuilder
    private func tabContent(for tab: Tab) -> some View {
        switch tab {
        case .today:
            DashboardView()
        case .log:
            LogView()
        case .insights:
            InsightsView()
        case .social:
            SocialView()
        case .settings:
            SettingsView()
        }
    }
}

#Preview {
    MainTabView()
}

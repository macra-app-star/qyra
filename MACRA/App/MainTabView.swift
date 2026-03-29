import SwiftUI
import SwiftData

// MARK: - Tab Bar Visibility State

@Observable @MainActor
final class TabBarState {
    var isVisible = true
}

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab: Tab = .home
    @State private var showFABMenu = false
    @State private var showManualEntry = false
    @State private var showCamera = false
    @State private var showBarcodeScanner = false
    @State private var showVoiceLog = false
    @State private var showExerciseLog = false
    @State private var showExerciseSearch = false
    @State private var showWorkoutPlanner = false
    @State private var showFoodDatabase = false
    @State private var showQuickAdd = false
    @State private var showVersus = false
    @State private var tabBarState = TabBarState()
    @Namespace private var tabAnimation

    enum Tab: Int, CaseIterable {
        case home, progress, groups, profile

        var title: String {
            switch self {
            case .home: "Home"
            case .progress: "Progress"
            case .groups: "Groups"
            case .profile: "Profile"
            }
        }

        var iconActive: String {
            switch self {
            case .home: "house.fill"
            case .progress: "chart.bar.fill"
            case .groups: "person.3.fill"
            case .profile: "person.fill"
            }
        }

        var iconInactive: String {
            switch self {
            case .home: "house"
            case .progress: "chart.bar"
            case .groups: "person.3"
            case .profile: "person"
            }
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab content — each wrapped in NavigationStack
            Group {
                switch selectedTab {
                case .home:
                    NavigationStack { TodayDashboardView() }
                case .progress:
                    NavigationStack { ProgressTabView() }
                case .groups:
                    NavigationStack { GroupsTabView() }
                case .profile:
                    NavigationStack { ProfileTabView() }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: tabBarState.isVisible ? 68 : 0)
            }

            // Floating tab bar with optional FAB
            if tabBarState.isVisible {
                HStack(spacing: 12) {
                    customTabBar

                    if selectedTab != .groups {
                        fabButton
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.snappy(duration: 0.25), value: selectedTab)
            }
        }
        .environment(tabBarState)
        .animation(.snappy(duration: 0.25), value: tabBarState.isVisible)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                NotificationCenter.default.post(name: .appBecameActive, object: nil)
            }
        }
        .overlay { ImportProgressToast() }
        .overlay {
            if showFABMenu {
                FABMenuOverlay(
                    onScanFood: {
                        showFABMenu = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { showBarcodeScanner = true }
                    },
                    onQuickAdd: {
                        showFABMenu = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { showQuickAdd = true }
                    },
                    onLogExercise: {
                        showFABMenu = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { showExerciseLog = true }
                    },
                    onSavedFoods: {
                        showFABMenu = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { showFoodDatabase = true }
                    },
                    onExerciseLibrary: {
                        showFABMenu = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { showExerciseSearch = true }
                    },
                    onWorkoutPlanner: {
                        showFABMenu = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { showWorkoutPlanner = true }
                    },
                    onVersus: {
                        showFABMenu = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { showVersus = true }
                    },
                    onLogMeal: {
                        showFABMenu = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { showFoodDatabase = true }
                    },
                    onDismiss: { showFABMenu = false }
                )
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView()
        }
        .sheet(isPresented: $showBarcodeScanner) {
            BarcodeScannerView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showVoiceLog) {
            VoiceLogView(modelContainer: modelContext.container)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showExerciseLog) {
            ExerciseTypeView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showExerciseSearch) {
            NavigationStack {
                ExerciseSearchView()
            }
            .tint(.accentColor)
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showWorkoutPlanner) {
            NavigationStack {
                WorkoutPlannerView()
            }
            .tint(.accentColor)
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showFoodDatabase) {
            NavigationStack {
                LogFoodView()
            }
            .tint(.accentColor)
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showQuickAdd) {
            NavigationStack {
                QuickAddView()
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showVersus) {
            CreateVersusView()
        }
        .onReceive(NotificationCenter.default.publisher(for: .openFoodDatabase)) { _ in
            showFoodDatabase = true
        }
    }

    // MARK: - Custom Floating Tab Bar

    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                let isSelected = selectedTab == tab

                Button {
                    DesignTokens.Haptics.selection()
                    withAnimation(.snappy(duration: 0.25)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: isSelected ? tab.iconActive : tab.iconInactive)
                            .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                            .frame(height: 22)

                        Text(tab.title)
                            .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                    }
                    .foregroundStyle(isSelected
                        ? (colorScheme == .dark ? .white : Color(.label))
                        : Color(.secondaryLabel)
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .contentShape(Rectangle())
                    .background(
                        Group {
                            if isSelected {
                                Capsule()
                                    .fill(colorScheme == .dark
                                        ? Color.white.opacity(0.1)
                                        : Color.black.opacity(0.05)
                                    )
                                    .matchedGeometryEffect(id: "tabIndicator", in: tabAnimation)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                            }
                        }
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.08), radius: 20, y: 6)
                .shadow(color: .black.opacity(0.03), radius: 1, y: 0)
        )
    }

    // MARK: - FAB Button

    private var fabButton: some View {
        Button {
            DesignTokens.Haptics.light()
            showFABMenu = true
        } label: {
            ZStack {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 52, height: 52)
                    .shadow(color: Color.accentColor.opacity(0.3), radius: 8, y: 4)

                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(FABPressStyle())
    }
}

// MARK: - FAB Press Style

private struct FABPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview {
    MainTabView()
}

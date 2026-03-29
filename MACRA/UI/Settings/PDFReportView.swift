import SwiftUI
import SwiftData

struct PDFReportView: View {

    @Environment(\.modelContext) private var modelContext
    @State private var selectedRange: ExportRange = .thirtyDays
    @State private var exportService = DataExportService()
    @State private var isSubscribed = false
    @State private var showPaywall = false

    enum ExportRange: String, CaseIterable {
        case sevenDays = "7 Days"
        case thirtyDays = "30 Days"
        case ninetyDays = "90 Days"
        case all = "All Time"

        var days: Int? {
            switch self {
            case .sevenDays: return 7
            case .thirtyDays: return 30
            case .ninetyDays: return 90
            case .all: return nil
            }
        }
    }

    var body: some View {
        Group {
            if isSubscribed {
                pdfContent
            } else {
                PremiumGateView(
                    featureName: "PDF Reports",
                    icon: "doc.text.fill",
                    showPaywall: $showPaywall
                )
            }
        }
        .task { isSubscribed = await SubscriptionService.shared.isSubscribed }
        .sheet(isPresented: $showPaywall) {
            OnboardingPaywallView(viewModel: OnboardingViewModel.preview)
        }
    }

    private var pdfContent: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            // Range picker
            Picker("Range", selection: $selectedRange) {
                ForEach(ExportRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, DesignTokens.Spacing.md)

            // Preview card
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                Text("Your report will include")
                    .font(DesignTokens.Typography.semibold(15))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                reportFeatureRow(icon: "chart.bar.fill", text: "Daily calorie summary")
                reportFeatureRow(icon: "circle.grid.3x3.fill", text: "Macro breakdown averages")
                reportFeatureRow(icon: "scalemass.fill", text: "Weight trend")
                reportFeatureRow(icon: "flame.fill", text: "Streak & adherence stats")
            }
            .padding(DesignTokens.Spacing.md)
            .premiumCard()
            .padding(.horizontal, DesignTokens.Spacing.md)

            Spacer()

            // Generate button
            Button {
                generateReport()
            } label: {
                if exportService.isGenerating {
                    ProgressView()
                        .tint(DesignTokens.Colors.surfaceElevated)
                } else {
                    Text("Generate Report")
                        .font(DesignTokens.Typography.semibold(17))
                }
            }
            .foregroundStyle(DesignTokens.Colors.surfaceElevated)
            .frame(maxWidth: .infinity)
            .frame(height: DesignTokens.Layout.buttonHeight)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Layout.buttonCornerRadius)
                    .fill(Color.accentColor)
            )
            .padding(.horizontal, DesignTokens.Spacing.md)
            .disabled(exportService.isGenerating)

            // Share button
            if let url = exportService.generatedURL {
                ShareLink(item: url) {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share Report")
                    }
                    .font(DesignTokens.Typography.semibold(17))
                    .foregroundStyle(DesignTokens.Colors.accent)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            if let error = exportService.errorMessage {
                Text(error)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.destructive)
            }
        }
        .padding(.top, DesignTokens.Spacing.lg)
        .background(DesignTokens.Colors.background)
        .navigationTitle("PDF Summary Report")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func reportFeatureRow(icon: String, text: String) -> some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: icon)
                .font(DesignTokens.Typography.icon(16))
                .foregroundStyle(DesignTokens.Colors.accent)
                .frame(width: 24)

            Text(text)
                .font(DesignTokens.Typography.bodyFont(14))
                .foregroundStyle(DesignTokens.Colors.textSecondary)
        }
    }

    private func generateReport() {
        Task {
            let endDate = Date()
            let startDate: Date
            if let days = selectedRange.days {
                startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) ?? endDate
            } else {
                startDate = Calendar.current.date(byAdding: .year, value: -2, to: endDate) ?? endDate
            }

            // Fetch real data from SwiftData
            let mealDescriptor = FetchDescriptor<MealLog>(
                predicate: #Predicate<MealLog> { meal in
                    meal.date >= startDate
                },
                sortBy: [SortDescriptor(\.date)]
            )
            let meals = (try? modelContext.fetch(mealDescriptor)) ?? []

            let weightDescriptor = FetchDescriptor<WeightEntry>(
                predicate: #Predicate<WeightEntry> { entry in
                    entry.timestamp >= startDate
                },
                sortBy: [SortDescriptor(\.timestamp)]
            )
            let weightEntries = (try? modelContext.fetch(weightDescriptor)) ?? []

            // Build daily calorie data
            let calendar = Calendar.current
            var dailyMap: [Date: (cals: Int, target: Int)] = [:]
            for meal in meals {
                let day = calendar.startOfDay(for: meal.date)
                let existing = dailyMap[day] ?? (cals: 0, target: 2000)
                dailyMap[day] = (cals: existing.cals + Int(meal.totalCalories), target: existing.target)
            }
            let dailyCalories = dailyMap
                .sorted { $0.key < $1.key }
                .map { (date: $0.key, calories: $0.value.cals, target: $0.value.target) }

            // Calculate macro averages
            let totalDays = max(Set(meals.map { calendar.startOfDay(for: $0.date) }).count, 1)
            let totalProtein = meals.flatMap(\.items).reduce(0.0) { $0 + $1.protein }
            let totalCarbs = meals.flatMap(\.items).reduce(0.0) { $0 + $1.carbs }
            let totalFat = meals.flatMap(\.items).reduce(0.0) { $0 + $1.fat }

            let macroAverages = (
                protein: Int(totalProtein / Double(totalDays)),
                carbs: Int(totalCarbs / Double(totalDays)),
                fat: Int(totalFat / Double(totalDays))
            )

            // Weight data
            let weights = weightEntries.map { (date: $0.timestamp, weight: $0.weightLbs) }

            // Adherence (days with meals / total days in range)
            let rangeDays = max(calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 1, 1)
            let daysWithMeals = Set(meals.map { calendar.startOfDay(for: $0.date) }).count
            let adherence = min(Int(Double(daysWithMeals) / Double(rangeDays) * 100), 100)

            do {
                _ = try await exportService.generateReport(
                    userName: "User",
                    dateRange: startDate...endDate,
                    dailyCalories: dailyCalories,
                    macroAverages: macroAverages,
                    weights: weights,
                    totalMealsLogged: meals.count,
                    adherencePercentage: adherence,
                    streak: daysWithMeals
                )
                DesignTokens.Haptics.success()
            } catch {
                exportService.errorMessage = "Failed to generate report"
            }
        }
    }
}

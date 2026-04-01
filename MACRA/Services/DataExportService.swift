import SwiftUI
import PDFKit

@Observable
@MainActor
final class DataExportService {

    var isGenerating = false
    var generatedURL: URL?
    var errorMessage: String?

    func generateReport(
        userName: String,
        dateRange: ClosedRange<Date>,
        dailyCalories: [(date: Date, calories: Int, target: Int)],
        macroAverages: (protein: Int, carbs: Int, fat: Int),
        weights: [(date: Date, weight: Double)],
        totalMealsLogged: Int,
        adherencePercentage: Int,
        streak: Int
    ) async throws -> URL {
        isGenerating = true
        defer { isGenerating = false }

        let pageSize = CGSize(width: 612, height: 792) // US Letter

        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, CGRect(origin: .zero, size: pageSize), nil)

        // Cover page
        renderPage(
            makeCoverPage(userName: userName, dateRange: dateRange),
            size: pageSize
        )

        // Summary page
        renderPage(
            makeSummaryPage(
                totalMealsLogged: totalMealsLogged,
                adherencePercentage: adherencePercentage,
                streak: streak,
                macroAverages: macroAverages,
                dailyCalories: dailyCalories
            ),
            size: pageSize
        )

        UIGraphicsEndPDFContext()

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("Qyra_Report_\(formatDateShort(Date())).pdf")
        try pdfData.write(to: tempURL)

        generatedURL = tempURL
        return tempURL
    }

    // MARK: - Render Helper

    private func renderPage<V: View>(_ content: V, size: CGSize) {
        UIGraphicsBeginPDFPage()
        let renderer = ImageRenderer(content:
            content.frame(width: size.width, height: size.height)
        )
        renderer.scale = 2.0
        if let image = renderer.uiImage {
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    // MARK: - Cover Page

    @ViewBuilder
    private func makeCoverPage(
        userName: String,
        dateRange: ClosedRange<Date>
    ) -> some View {
        ZStack {
            Color(uiColor: UIColor(red: 0.04, green: 0.04, blue: 0.04, alpha: 1))

            VStack(spacing: 32) {
                Spacer()

                HStack(spacing: 0) {
                    Text("Qyra")
                        .font(DesignTokens.Typography.headlineFont(36))
                        .foregroundStyle(.white)
                    Text("\u{00AE}")
                        .font(DesignTokens.Typography.bodyFont(12))
                        .foregroundStyle(.white.opacity(0.5))
                        .baselineOffset(18)
                }

                Text("Nutrition Report")
                    .font(DesignTokens.Typography.medium(18))
                    .foregroundStyle(.white.opacity(0.6))

                Spacer()

                VStack(spacing: 8) {
                    Text(userName)
                        .font(DesignTokens.Typography.semibold(20))
                        .foregroundStyle(.white)

                    Text("\(formatDate(dateRange.lowerBound)) \u{2013} \(formatDate(dateRange.upperBound))")
                        .font(DesignTokens.Typography.bodyFont(14))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()
            }
        }
    }

    // MARK: - Summary Page

    @ViewBuilder
    private func makeSummaryPage(
        totalMealsLogged: Int,
        adherencePercentage: Int,
        streak: Int,
        macroAverages: (protein: Int, carbs: Int, fat: Int),
        dailyCalories: [(date: Date, calories: Int, target: Int)]
    ) -> some View {
        let darkText = Color(uiColor: UIColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1))
        let secondaryText = Color(uiColor: UIColor(red: 0.54, green: 0.54, blue: 0.54, alpha: 1))
        let proteinColor = Color.accentColor
        let carbsColor = Color.accentColor
        let fatColor = Color.accentColor

        ZStack {
            Color.white

            VStack(alignment: .leading, spacing: 24) {
                Text("Summary")
                    .font(DesignTokens.Typography.headlineFont(24))
                    .foregroundStyle(darkText)
                    .padding(.top, 40)

                // Stats grid
                HStack(spacing: 20) {
                    statBox(label: "Meals Logged", value: "\(totalMealsLogged)", textColor: darkText, labelColor: secondaryText)
                    statBox(label: "Adherence", value: "\(adherencePercentage)%", textColor: darkText, labelColor: secondaryText)
                    statBox(label: "Streak", value: "\(streak) days", textColor: darkText, labelColor: secondaryText)
                }

                // Macro averages
                VStack(alignment: .leading, spacing: 12) {
                    Text("Daily Macro Averages")
                        .font(DesignTokens.Typography.semibold(16))
                        .foregroundStyle(darkText)

                    HStack(spacing: 24) {
                        macroBox(label: "Protein", value: "\(macroAverages.protein)g", color: proteinColor, labelColor: secondaryText)
                        macroBox(label: "Carbs", value: "\(macroAverages.carbs)g", color: carbsColor, labelColor: secondaryText)
                        macroBox(label: "Fat", value: "\(macroAverages.fat)g", color: fatColor, labelColor: secondaryText)
                    }
                }

                // Calorie trend
                if !dailyCalories.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Calorie Trend")
                            .font(DesignTokens.Typography.semibold(16))
                            .foregroundStyle(darkText)

                        let avgCalories = dailyCalories.map(\.calories).reduce(0, +) / max(dailyCalories.count, 1)
                        let avgTarget = dailyCalories.map(\.target).reduce(0, +) / max(dailyCalories.count, 1)

                        Text("Average: \(avgCalories) cal / \(avgTarget) cal target")
                            .font(DesignTokens.Typography.bodyFont(14))
                            .foregroundStyle(secondaryText)
                    }
                }

                Spacer()

                // Footer
                HStack {
                    Spacer()
                    Text("Generated by Qyra")
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(Color(uiColor: UIColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1)))
                    Spacer()
                }
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 40)
        }
    }

    // MARK: - Component Builders

    @ViewBuilder
    private func statBox(label: String, value: String, textColor: Color, labelColor: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(DesignTokens.Typography.numeric(28))
                .foregroundStyle(textColor)
            Text(label)
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(labelColor)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func macroBox(label: String, value: String, color: Color, labelColor: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(DesignTokens.Typography.semibold(20))
                .foregroundStyle(color)
            Text(label)
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(labelColor)
        }
    }

    // MARK: - Date Formatting

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func formatDateShort(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: date)
    }
}

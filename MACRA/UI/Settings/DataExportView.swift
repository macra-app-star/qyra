import SwiftUI
import SwiftData

struct DataExportView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedRange = ExportRange.last30Days
    @State private var isExporting = false
    @State private var showShareSheet = false
    @State private var exportURL: URL?
    @State private var mealCount = 0
    @State private var errorMessage: String?

    enum ExportRange: String, CaseIterable {
        case last7Days = "Last 7 Days"
        case last30Days = "Last 30 Days"
        case last90Days = "Last 90 Days"
        case allTime = "All Time"

        var days: Int? {
            switch self {
            case .last7Days: return 7
            case .last30Days: return 30
            case .last90Days: return 90
            case .allTime: return nil
            }
        }
    }

    var body: some View {
        List {
            Section("Date Range") {
                Picker("Range", selection: $selectedRange) {
                    ForEach(ExportRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .listRowBackground(DesignTokens.Colors.surface)
            }

            Section("Preview") {
                HStack {
                    Text("Meals Found")
                    Spacer()
                    Text("\(mealCount)")
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }
                .listRowBackground(DesignTokens.Colors.surface)
            }

            Section("Format") {
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                    Text("CSV (Comma Separated Values)")
                    Spacer()
                    Image(systemName: "checkmark")
                        .foregroundStyle(DesignTokens.Colors.accent)
                }
                .listRowBackground(DesignTokens.Colors.surface)
            }

            Section {
                Button {
                    Task { await exportData() }
                } label: {
                    HStack {
                        Spacer()
                        if isExporting {
                            ProgressView()
                                .tint(DesignTokens.Colors.textPrimary)
                        } else {
                            Text("Export Data")
                                .font(DesignTokens.Typography.headline)
                                .foregroundStyle(DesignTokens.Colors.textPrimary)
                        }
                        Spacer()
                    }
                }
                .disabled(isExporting || mealCount == 0)
                .listRowBackground(DesignTokens.Colors.surface)
            }

            if let error = errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(DesignTokens.Colors.destructive)
                        .font(DesignTokens.Typography.caption)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(DesignTokens.Colors.background)
        .navigationTitle("Export Data")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedRange) { _, _ in
            Task { await countMeals() }
        }
        .task {
            await countMeals()
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = exportURL {
                ShareSheet(items: [url])
            }
        }
    }

    private func countMeals() async {
        let startDate = startDateForRange()
        let descriptor = FetchDescriptor<MealLog>(
            predicate: #Predicate<MealLog> { meal in
                meal.date >= startDate
            }
        )
        mealCount = (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    private func exportData() async {
        isExporting = true
        errorMessage = nil

        do {
            let startDate = startDateForRange()
            let descriptor = FetchDescriptor<MealLog>(
                predicate: #Predicate<MealLog> { meal in
                    meal.date >= startDate
                },
                sortBy: [SortDescriptor(\.date)]
            )

            let meals = try modelContext.fetch(descriptor)

            var csv = "Date,Meal Type,Food Name,Calories,Protein (g),Carbs (g),Fat (g),Serving Size,Entry Method\n"

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"

            for meal in meals {
                for item in meal.items {
                    let row = [
                        dateFormatter.string(from: meal.date),
                        meal.mealType.rawValue,
                        "\"\(item.foodName)\"",
                        String(format: "%.1f", item.calories),
                        String(format: "%.1f", item.protein),
                        String(format: "%.1f", item.carbs),
                        String(format: "%.1f", item.fat),
                        "\"\(item.servingSize ?? "")\"",
                        item.entryMethod.rawValue
                    ].joined(separator: ",")
                    csv += row + "\n"
                }
            }

            let tempDir = FileManager.default.temporaryDirectory
            let fileURL = tempDir.appendingPathComponent("macra_export_\(Int(Date().timeIntervalSince1970)).csv")
            try csv.write(to: fileURL, atomically: true, encoding: .utf8)

            exportURL = fileURL
            showShareSheet = true
        } catch {
            errorMessage = "Export failed: \(error.localizedDescription)"
        }

        isExporting = false
    }

    private func startDateForRange() -> Date {
        if let days = selectedRange.days {
            return Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date.distantPast
        }
        return Date.distantPast
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

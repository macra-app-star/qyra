import SwiftUI
import SwiftData

struct FoodSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: FoodSearchViewModel
    @State private var showManualEntry = false
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        _viewModel = State(initialValue: FoodSearchViewModel(modelContainer: modelContainer))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DesignTokens.Colors.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Meal type picker
                    Picker("Meal Type", selection: $viewModel.selectedMealType) {
                        ForEach(MealType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, DesignTokens.Spacing.md)
                    .padding(.vertical, DesignTokens.Spacing.sm)

                    if viewModel.results.isEmpty && !viewModel.isSearching {
                        if viewModel.searchText.isEmpty {
                            recentSearchesSection
                        } else {
                            emptyResultsView
                        }
                    } else {
                        resultsList
                    }
                }
            }
            .navigationTitle("Search Food")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $viewModel.searchText, prompt: "Search foods...")
            .onChange(of: viewModel.searchText) { _, _ in
                viewModel.onSearchTextChanged()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onChange(of: viewModel.didSave) { _, saved in
                if saved {
                    DesignTokens.Haptics.success()
                    dismiss()
                }
            }
            .sheet(isPresented: $showManualEntry) {
                ManualEntryView(modelContainer: modelContainer)
            }
        }
    }

    private var addManuallyButton: some View {
        Button {
            showManualEntry = true
        } label: {
            Text("Can't find it? Add manually")
                .font(.subheadline)
                .foregroundStyle(Color.accentColor)
                .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Results List

    private var resultsList: some View {
        List {
            if viewModel.isSearching {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(DesignTokens.Colors.textSecondary)
                    Spacer()
                }
                .listRowBackground(DesignTokens.Colors.surface)
            }

            ForEach(viewModel.results) { result in
                NavigationLink {
                    FoodDetailView(
                        food: result,
                        mealType: viewModel.selectedMealType
                    ) {
                        viewModel.didSave = true
                    }
                } label: {
                    foodResultRow(result)
                }
                .listRowBackground(DesignTokens.Colors.surface)
                .swipeActions(edge: .trailing) {
                    Button {
                        Task { await viewModel.quickAdd(result) }
                    } label: {
                        Label("Quick Add", systemImage: "plus.circle.fill")
                    }
                    .tint(.green.opacity(0.85))
                }
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.destructive)
                    .listRowBackground(DesignTokens.Colors.surface)
            }

            addManuallyButton
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func foodResultRow(_ result: FoodAnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(result.name)
                .font(DesignTokens.Typography.body)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
                .lineLimit(2)

            HStack(spacing: DesignTokens.Spacing.md) {
                if let brand = result.brand {
                    Text(brand)
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.Colors.textTertiary)
                        .lineLimit(1)
                }

                Spacer()

                Text("\(Int(result.calories)) cal")
                    .font(DesignTokens.Typography.subheadline)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)

                Text(result.servingSize ?? "100g")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
            }

            HStack(spacing: DesignTokens.Spacing.sm) {
                Text("P: \(Int(result.protein))g")
                Text("C: \(Int(result.carbs))g")
                Text("F: \(Int(result.fat))g")
            }
            .font(DesignTokens.Typography.caption)
            .foregroundStyle(DesignTokens.Colors.textTertiary)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Recent Searches

    private var recentSearchesSection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                if !viewModel.recentSearches.isEmpty {
                    HStack {
                        Text("Recent Searches")
                            .font(DesignTokens.Typography.headline)
                            .foregroundStyle(DesignTokens.Colors.textPrimary)

                        Spacer()

                        Button("Clear") {
                            viewModel.clearRecentSearches()
                        }
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.Colors.textTertiary)
                    }

                    ForEach(viewModel.recentSearches, id: \.self) { query in
                        Button {
                            viewModel.selectRecentSearch(query)
                        } label: {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                    .foregroundStyle(DesignTokens.Colors.textTertiary)
                                Text(query)
                                    .font(DesignTokens.Typography.body)
                                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                                Spacer()
                            }
                        }
                    }
                } else {
                    EmptyDataView(
                        title: "Search Foods",
                        subtitle: "Search millions of foods from USDA FoodData Central."
                    )
                    .padding(.top, 48)
                }
            }
            .padding(DesignTokens.Spacing.md)
        }
    }

    private var emptyResultsView: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            EmptyDataView(
                title: "No Results",
                subtitle: "Try a different search term."
            )
            .padding(.top, 48)

            addManuallyButton
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

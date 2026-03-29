import SwiftUI
import SwiftData

struct LogFoodView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: FoodSearchViewModel?
    @State private var selectedTab = "All"
    @State private var showManualEntry = false
    @State private var quickMealDetector = QuickMealDetector()

    @Query(sort: \QuickMeal.logCount, order: .reverse)
    private var allQuickMeals: [QuickMeal]

    @Query(filter: #Predicate<MealItem> { $0.isFavorite == true }, sort: \MealItem.createdAt, order: .reverse)
    private var favoriteMealItems: [MealItem]

    @Query(sort: \MealLog.date, order: .reverse)
    private var allMealLogs: [MealLog]

    private var timeRelevantQuickMeals: [QuickMeal] {
        quickMealDetector.timeRelevantQuickMeals(from: allQuickMeals)
    }

    /// Deduplicated saved foods (unique by foodName, keeping most recent)
    private var uniqueSavedFoods: [MealItem] {
        var seen = Set<String>()
        return favoriteMealItems.filter { item in
            let key = item.foodName.lowercased()
            if seen.contains(key) { return false }
            seen.insert(key)
            return true
        }
    }

    /// Recent meal items from last 30 days, grouped by food name with frequency
    private var recentFoodsWithFrequency: [(item: MealItem, count: Int)] {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let recentLogs = allMealLogs.filter { $0.date >= thirtyDaysAgo }
        let allItems = recentLogs.flatMap { $0.items }

        var frequencyMap: [String: (item: MealItem, count: Int)] = [:]
        for item in allItems {
            let key = item.foodName.lowercased()
            if let existing = frequencyMap[key] {
                frequencyMap[key] = (item: existing.item, count: existing.count + 1)
            } else {
                frequencyMap[key] = (item: item, count: 1)
            }
        }

        return frequencyMap.values
            .sorted { $0.count > $1.count }
    }

    private let tabOptions = ["All", "My foods", "My meals", "Saved foods"]

    var body: some View {
        VStack(spacing: 0) {
            // Quick log section
            if !timeRelevantQuickMeals.isEmpty {
                VStack(alignment: .leading, spacing: DesignTokens.Layout.tightGap) {
                    Text("Quick log")
                        .font(DesignTokens.Typography.medium(14))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                        .padding(.horizontal, DesignTokens.Layout.screenMargin)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DesignTokens.Layout.itemGap) {
                            ForEach(timeRelevantQuickMeals) { meal in
                                QuickMealCard(meal: meal) { onQuickLog(meal) }
                            }
                        }
                        .padding(.horizontal, DesignTokens.Layout.screenMargin)
                    }
                }
                .padding(.bottom, DesignTokens.Layout.tightGap)
            }

            // Tab selector
            TimeFilterPills(
                options: tabOptions,
                selection: $selectedTab
            )
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm)

            // Content area
            if selectedTab == "All", let vm = viewModel {
                searchContent(vm)
            } else if selectedTab == "Saved foods" {
                savedFoodsContent
            } else if selectedTab == "My meals" {
                recentFoodsContent
            } else {
                Spacer()
                emptyStateView
                Spacer()
            }
        }
        .background(DesignTokens.Colors.background)
        .navigationTitle("My Food")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: searchTextBinding, prompt: "Search foods...")
        .onChange(of: searchTextBinding.wrappedValue) { _, _ in
            viewModel?.onSearchTextChanged()
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = FoodSearchViewModel(modelContainer: modelContext.container)
            }
        }
        .onChange(of: viewModel?.didSave ?? false) { _, saved in
            if saved {
                DesignTokens.Haptics.success()
                dismiss()
            }
        }
        .sheet(isPresented: $showManualEntry) {
            ManualEntryView(modelContainer: modelContext.container)
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

    // MARK: - Quick Log

    private func onQuickLog(_ meal: QuickMeal) {
        guard let vm = viewModel else { return }

        let items = meal.foodItems.map { food in
            NewMealItem(
                foodName: food.name,
                calories: food.calories,
                protein: food.protein,
                carbs: food.carbs,
                fat: food.fat,
                servingSize: food.servingSize,
                entryMethod: .quick
            )
        }

        Task {
            do {
                let repo = MealRepository(modelContainer: modelContext.container)
                try await repo.addMeal(
                    date: Date(),
                    mealType: vm.selectedMealType,
                    items: items
                )

                // Update the QuickMeal's last logged date and count
                meal.lastLogged = .now
                meal.logCount += 1
                try? modelContext.save()

                vm.didSave = true
            } catch {
                vm.errorMessage = "Failed to log meal: \(error.localizedDescription)"
            }
        }
    }

    private var searchTextBinding: Binding<String> {
        Binding(
            get: { viewModel?.searchText ?? "" },
            set: { viewModel?.searchText = $0 }
        )
    }

    // MARK: - Search Content

    @ViewBuilder
    private func searchContent(_ vm: FoodSearchViewModel) -> some View {
        if vm.results.isEmpty && !vm.isSearching {
            if vm.searchText.isEmpty {
                recentSearchesSection(vm)
            } else {
                Spacer()
                emptySearchView
                Spacer()
            }
        } else {
            resultsList(vm)
        }
    }

    // MARK: - Results List

    private func resultsList(_ vm: FoodSearchViewModel) -> some View {
        List {
            if vm.isSearching {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(DesignTokens.Colors.textSecondary)
                    Spacer()
                }
                .listRowBackground(DesignTokens.Colors.surface)
            }

            ForEach(vm.results) { result in
                NavigationLink {
                    FoodDetailView(
                        food: result,
                        mealType: vm.selectedMealType
                    ) {
                        vm.didSave = true
                    }
                } label: {
                    foodResultRow(result)
                }
                .listRowBackground(DesignTokens.Colors.surface)
                .swipeActions(edge: .trailing) {
                    Button {
                        Task { await vm.quickAdd(result) }
                    } label: {
                        Label("Quick Add", systemImage: "plus.circle.fill")
                    }
                    .tint(.green.opacity(0.85))
                }
            }

            if let error = vm.errorMessage {
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

    private func recentSearchesSection(_ vm: FoodSearchViewModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                if !vm.recentSearches.isEmpty {
                    HStack {
                        Text("Recent Searches")
                            .font(DesignTokens.Typography.headline)
                            .foregroundStyle(DesignTokens.Colors.textPrimary)

                        Spacer()

                        Button("Clear") {
                            vm.clearRecentSearches()
                        }
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.Colors.textTertiary)
                    }

                    ForEach(vm.recentSearches, id: \.self) { query in
                        Button {
                            vm.selectRecentSearch(query)
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
                        subtitle: "Search millions of foods from USDA and FatSecret databases."
                    )
                    .padding(.top, 48)
                }
            }
            .padding(DesignTokens.Spacing.md)
        }
    }

    // MARK: - Saved Foods

    @ViewBuilder
    private var savedFoodsContent: some View {
        if uniqueSavedFoods.isEmpty {
            Spacer()
            EmptyDataView(
                title: "No Saved Foods",
                subtitle: "Tap the heart on any food to save it here."
            )
            Spacer()
        } else {
            List {
                ForEach(uniqueSavedFoods, id: \.id) { item in
                    NavigationLink {
                        FoodDetailView(
                            food: foodAnalysisResult(from: item),
                            mealType: viewModel?.selectedMealType ?? FoodDetailView.defaultMealType
                        ) {
                            viewModel?.didSave = true
                        }
                    } label: {
                        savedFoodRow(item)
                    }
                    .listRowBackground(DesignTokens.Colors.surface)
                    .swipeActions(edge: .trailing) {
                        Button {
                            quickAddMealItem(item)
                        } label: {
                            Label("Quick Add", systemImage: "plus.circle.fill")
                        }
                        .tint(.green.opacity(0.85))
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }

    private func savedFoodRow(_ item: MealItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.foodName)
                .font(DesignTokens.Typography.body)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
                .lineLimit(2)

            HStack(spacing: DesignTokens.Spacing.md) {
                Spacer()

                Text("\(Int(item.calories)) cal")
                    .font(DesignTokens.Typography.subheadline)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)

                if let serving = item.servingSize {
                    Text(serving)
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.Colors.textTertiary)
                }
            }

            HStack(spacing: DesignTokens.Spacing.sm) {
                Text("P: \(Int(item.protein))g")
                Text("C: \(Int(item.carbs))g")
                Text("F: \(Int(item.fat))g")
            }
            .font(DesignTokens.Typography.caption)
            .foregroundStyle(DesignTokens.Colors.textTertiary)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Recent Foods

    @ViewBuilder
    private var recentFoodsContent: some View {
        if recentFoodsWithFrequency.isEmpty {
            Spacer()
            EmptyDataView(
                title: "No Recent Foods",
                subtitle: "Foods you log will appear here for quick access."
            )
            Spacer()
        } else {
            List {
                ForEach(recentFoodsWithFrequency, id: \.item.id) { entry in
                    NavigationLink {
                        FoodDetailView(
                            food: foodAnalysisResult(from: entry.item),
                            mealType: viewModel?.selectedMealType ?? FoodDetailView.defaultMealType
                        ) {
                            viewModel?.didSave = true
                        }
                    } label: {
                        recentFoodRow(item: entry.item, count: entry.count)
                    }
                    .listRowBackground(DesignTokens.Colors.surface)
                    .swipeActions(edge: .trailing) {
                        Button {
                            quickAddMealItem(entry.item)
                        } label: {
                            Label("Quick Add", systemImage: "plus.circle.fill")
                        }
                        .tint(.green.opacity(0.85))
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }

    private func recentFoodRow(item: MealItem, count: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.foodName)
                .font(DesignTokens.Typography.body)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
                .lineLimit(2)

            HStack(spacing: DesignTokens.Spacing.md) {
                Text("Logged \(count) time\(count == 1 ? "" : "s")")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.textTertiary)

                Spacer()

                Text("\(Int(item.calories)) cal")
                    .font(DesignTokens.Typography.subheadline)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }

            HStack(spacing: DesignTokens.Spacing.sm) {
                Text("P: \(Int(item.protein))g")
                Text("C: \(Int(item.carbs))g")
                Text("F: \(Int(item.fat))g")
            }
            .font(DesignTokens.Typography.caption)
            .foregroundStyle(DesignTokens.Colors.textTertiary)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Helpers

    private func foodAnalysisResult(from item: MealItem) -> FoodAnalysisResult {
        FoodAnalysisResult(
            name: item.foodName,
            calories: item.calories,
            protein: item.protein,
            carbs: item.carbs,
            fat: item.fat,
            fiber: item.fiber,
            sugar: item.sugar,
            sodium: item.sodium,
            servingSize: item.servingSize,
            confidence: item.confidenceScore ?? 80,
            barcode: item.barcode,
            imageURL: item.imageURL
        )
    }

    private func quickAddMealItem(_ item: MealItem) {
        let mealType = viewModel?.selectedMealType ?? FoodDetailView.defaultMealType
        let newItem = NewMealItem(
            foodName: item.foodName,
            calories: item.calories,
            protein: item.protein,
            carbs: item.carbs,
            fat: item.fat,
            fiber: item.fiber,
            sugar: item.sugar,
            sodium: item.sodium,
            servingSize: item.servingSize,
            entryMethod: .quick,
            confidenceScore: item.confidenceScore,
            barcode: item.barcode,
            imageURL: item.imageURL,
            isFavorite: item.isFavorite
        )

        Task {
            do {
                let repo = MealRepository(modelContainer: modelContext.container)
                try await repo.addMeal(
                    date: Date(),
                    mealType: mealType,
                    items: [newItem]
                )
                viewModel?.didSave = true
            } catch {
                viewModel?.errorMessage = "Failed to log food: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Empty States

    private var emptySearchView: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            EmptyDataView(
                title: "No Results",
                subtitle: "Try a different search term."
            )

            addManuallyButton
        }
    }

    @ViewBuilder
    private var emptyStateView: some View {
        switch selectedTab {
        case "My foods":
            EmptyDataView(
                title: "No Custom Foods",
                subtitle: "Create your own food entries to see them here."
            )
        case "My meals":
            EmptyDataView(
                title: "No Saved Meals",
                subtitle: "Save meal combinations for quick logging."
            )
        case "Saved foods":
            EmptyDataView(
                title: "No Saved Foods",
                subtitle: "Bookmark foods from search results for easy access."
            )
        default:
            EmptyView()
        }
    }
}

#Preview {
    LogFoodView()
}

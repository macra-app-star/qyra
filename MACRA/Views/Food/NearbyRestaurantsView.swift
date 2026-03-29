import SwiftUI
import CoreLocation
import MapKit

struct NearbyRestaurantsView: View {
    @State private var service = RestaurantSearchService()
    @State private var locationManager = LocationHelper()
    @State private var selectedRestaurant: RestaurantSearchService.RestaurantResult?
    @State private var searchText = ""
    @State private var showOrderInput = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if service.isSearching {
                    loadingState
                } else if let error = service.errorMessage {
                    errorState(error)
                } else if service.nearbyRestaurants.isEmpty {
                    emptyState
                } else {
                    restaurantList
                }
            }
            .navigationTitle("Nearby")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(DesignTokens.Typography.medium(16))
                }
            }
            .searchable(text: $searchText, prompt: "Search restaurants")
            .onSubmit(of: .search) {
                guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                if let location = locationManager.lastLocation {
                    Task { await service.searchByName(searchText, near: location) }
                }
            }
            .sheet(isPresented: $showOrderInput) {
                if let restaurant = selectedRestaurant {
                    RestaurantOrderView(restaurantName: restaurant.name)
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                }
            }
        }
        .task {
            if let location = locationManager.lastLocation {
                await service.searchNearby(location: location)
            } else {
                locationManager.requestLocation()
            }
        }
        .onChange(of: locationManager.lastLocation) { _, newLocation in
            if let location = newLocation, service.nearbyRestaurants.isEmpty {
                Task { await service.searchNearby(location: location) }
            }
        }
    }

    // MARK: - States

    private var loadingState: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            ProgressView()
            Text("Finding nearby restaurants...")
                .font(DesignTokens.Typography.bodyFont(15))
                .foregroundStyle(DesignTokens.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: "location.slash")
                .font(DesignTokens.Typography.icon(40))
                .foregroundStyle(DesignTokens.Colors.textTertiary)
            Text(message)
                .font(DesignTokens.Typography.bodyFont(15))
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                if let location = locationManager.lastLocation {
                    Task { await service.searchNearby(location: location) }
                } else {
                    locationManager.requestLocation()
                }
            } label: {
                Text("Try Again")
                    .font(DesignTokens.Typography.medium(15))
                    .foregroundStyle(DesignTokens.Colors.accent)
            }
            .padding(.top, DesignTokens.Spacing.sm)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        EmptyDataView(
            title: "No Restaurants Found",
            subtitle: "Try searching by name or check your location settings."
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Restaurant List

    private var restaurantList: some View {
        ScrollView {
            LazyVStack(spacing: DesignTokens.Spacing.sm) {
                ForEach(service.nearbyRestaurants) { restaurant in
                    restaurantRow(restaurant)
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.top, DesignTokens.Spacing.sm)
        }
    }

    private func restaurantRow(_ restaurant: RestaurantSearchService.RestaurantResult) -> some View {
        Button {
            selectedRestaurant = restaurant
            showOrderInput = true
        } label: {
            HStack(spacing: DesignTokens.Spacing.md) {
                Image(systemName: "fork.knife.circle.fill")
                    .font(DesignTokens.Typography.icon(32))
                    .foregroundStyle(DesignTokens.Colors.accent)

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                    Text(restaurant.name)
                        .font(DesignTokens.Typography.semibold(15))
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    if let distance = restaurant.distance {
                        Text(formatDistance(distance))
                            .font(DesignTokens.Typography.caption)
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(DesignTokens.Typography.icon(14))
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
            }
            .padding(DesignTokens.Spacing.md)
            .premiumCard()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func formatDistance(_ meters: Double) -> String {
        if meters < 1000 {
            return "\(Int(meters))m away"
        } else {
            return String(format: "%.1f km away", meters / 1000)
        }
    }
}

#Preview {
    NearbyRestaurantsView()
}

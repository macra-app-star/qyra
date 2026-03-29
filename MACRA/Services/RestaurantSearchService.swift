import MapKit
import CoreLocation

@Observable @MainActor
class RestaurantSearchService {
    var nearbyRestaurants: [RestaurantResult] = []
    var isSearching = false
    var errorMessage: String?

    struct RestaurantResult: Identifiable, Hashable {
        let id = UUID()
        let name: String
        let category: String?
        let distance: Double? // meters
        let coordinate: CLLocationCoordinate2D

        // Hashable conformance without coordinate
        func hash(into hasher: inout Hasher) { hasher.combine(id) }
        static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
    }

    func searchNearby(location: CLLocation) async {
        isSearching = true
        errorMessage = nil
        defer { isSearching = false }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "restaurant"
        request.region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 1000,
            longitudinalMeters: 1000
        )
        request.resultTypes = .pointOfInterest

        do {
            let search = MKLocalSearch(request: request)
            let response = try await search.start()
            nearbyRestaurants = response.mapItems.compactMap { item in
                guard let name = item.name else { return nil }
                return RestaurantResult(
                    name: name,
                    category: item.pointOfInterestCategory?.rawValue,
                    distance: item.placemark.location.map { location.distance(from: $0) },
                    coordinate: item.placemark.coordinate
                )
            }
            .sorted { ($0.distance ?? .infinity) < ($1.distance ?? .infinity) }
        } catch {
            errorMessage = "Could not find nearby restaurants"
        }
    }

    func searchByName(_ query: String, near location: CLLocation) async {
        isSearching = true
        errorMessage = nil
        defer { isSearching = false }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 5000,
            longitudinalMeters: 5000
        )
        request.resultTypes = .pointOfInterest

        do {
            let search = MKLocalSearch(request: request)
            let response = try await search.start()
            nearbyRestaurants = response.mapItems.compactMap { item in
                guard let name = item.name else { return nil }
                return RestaurantResult(
                    name: name,
                    category: item.pointOfInterestCategory?.rawValue,
                    distance: item.placemark.location.map { location.distance(from: $0) },
                    coordinate: item.placemark.coordinate
                )
            }
            .sorted { ($0.distance ?? .infinity) < ($1.distance ?? .infinity) }
        } catch {
            errorMessage = "Could not find restaurants matching '\(query)'"
        }
    }
}

import SwiftUI
import SwiftData

struct AddPlaceView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @StateObject private var locationService = LocationService()
    @State private var searchText = ""
    @State private var pinCoordinate: CLLocationCoordinate2D?
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Map
                MapView(
                    pinCoordinate: $pinCoordinate
                ) { coordinate in
                    pinCoordinate = coordinate
                }
                .frame(height: 280)
                .cornerRadius(12)

                Divider()

                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search for a place", text: $searchText)
                        .textFieldStyle(.plain)
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .cornerRadius(8)

                // Demo suggestions
                if !searchText.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(demoSuggestions, id: \.self) { suggestion in
                                Button {
                                    searchText = suggestion
                                    findLocation(for: suggestion)
                                } label: {
                                    Text(suggestion)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.secondary.opacity(0.2))
                                        .cornerRadius(16)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                    }
                }

                Spacer()

                // Save button
                Button {
                    savePlace()
                } label: {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(isSaving ? "Saving…" : "Save Office")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isSaving ? Color.gray : Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
                }
                .disabled(isSaving || pinCoordinate == nil || searchText.isEmpty)
                .padding(.horizontal)
                .padding(.bottom, 32)

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }
            }
            .navigationTitle("Add Office")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                locationService.setModelContext(modelContext)
                locationService.requestAuthorization()
                // Center the map on the user's current location
                if let loc = locationService.currentLocation {
                    pinCoordinate = loc.coordinate
                }
            }
        }
    }

    private var demoSuggestions: [String] {
        ["Airport", "Convention Center", "City Hall", "Business Park", "Office Park", "Tech Hub"]
    }

    private func findLocation(for query: String) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )

        let search = MKLocalSearch(request: request)
        search.start { response, error in
            if let error = error {
                errorMessage = error.localizedDescription
                return
            }
            guard let result = response?.mapItems.first else { return }
            let coord = result.placemark.coordinate
            pinCoordinate = coord
            searchText = result.placemark.title ?? query
        }
    }

    private func savePlace() {
        guard let coordinate = pinCoordinate else { return }
        isSaving = true
        errorMessage = nil

        let place = Place(
            name: searchText.isEmpty ? "Office \(placesCount() + 1)" : searchText,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            label: ""
        )

        modelContext.insert(place)
        try? modelContext.save()

        locationService.startMonitoring(placeId: place.id)

        isSaving = false
        dismiss()
    }

    private func placesCount() -> Int {
        (try? modelContext?.fetch(FetchDescriptor<Place>())) ?? []
            .count
    }
}

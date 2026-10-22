import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query var places: [Place]

    @StateObject private var locationService = LocationService()
    @State private var selectedPlace: Place?

    var body: some View {
       NavigationSplitView {
            List(places) { place in
                NavigationLink(value: place) {
                    PlaceRow(place: place)
                }
                .contextMenu {
                    Button("View Visits") {
                        selectedPlace = place
                    }
                    .disabled(place.visits.isEmpty)
                    Button("Export Visits (PDF)") {
                        exportPlace(place)
                    }
                    .disabled(place.visits.isEmpty)
                }
            }
            .listStyle(.inset)
            .navigationTitle("Office Visits")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        selectedPlace = nil
                    } label: {
                        Label("Add Office", systemImage: "plus")
                    }
                }
            }
        } detail: {
            if let place = selectedPlace {
                PlaceDetailView(place: place)
            } else {
                ContentUnavailableView("No offices yet", systemImage: "building.2", description: Text("Tap the + button to add an office location."))
            }
        }
        .environmentObject(locationService)
        .onAppear {
            locationService.setModelContext(modelContext)
        }
    }

    private func exportPlace(_ place: Place) {
        let fetch = FetchDescriptor<Visit>(predicate: #Predicate<Visit> { $0.placeId == place.id })
        let allVisits = (try? modelContext.fetch(fetch)) ?? []
        let csv = ExportService.csvData(for: allVisits, places: places)
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("office_visits_\(place.id.uuidString).csv")
        try? csv.data(using: .utf8)?.write(to: url)
        showExportNotification(for: url)
    }

    private func showExportNotification(for url: URL) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            let content = UNMutableNotificationContent()
            content.title = "Export Complete"
            content.body = "Exported \(url.lastPathComponent) to Files."
            content.sound = .default
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            center.add(request)
        }
    }
}

struct PlaceRow: View {
    let place: Place

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(place.name)
                    .font(.headline)
                Text(place.label.isEmpty ? "Office" : place.label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let lastVisit = place.visits.last {
                VisitSummaryView(visit: lastVisit)
            } else {
                Text("No visits yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct VisitSummaryView: View {
    let visit: Visit

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(visit.durationSeconds.map { "\(Int($0 / 60))m" } ?? "—")
                .font(.caption)
            Text(visit.status == .completed ? "Left" : "At")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

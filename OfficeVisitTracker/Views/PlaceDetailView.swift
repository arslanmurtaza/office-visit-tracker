import SwiftUI
import SwiftData

struct PlaceDetailView: View {
    let place: Place

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var visits: [Visit]

    @State private var exportProgress: String?

    var completedVisits: [Visit] {
        visits.filter { $0.status == .completed }
    }

    var activeVisit: Visit? {
        visits.first { $0.status == .active }
    }

    var body: some View {
        List {
            Section("Place") {
                PlaceInfoRow(label: "Name", value: place.name)
                PlaceInfoRow(label: "Created", value: place.createdAt, format: .dateTime)
                PlaceInfoRow(label: "Location", value: "\(place.latitude, specifier: "%.5f"), \(place.longitude, specifier: "%.5f")")
            }

            if let active = activeVisit {
                Section("Current Visit") {
                    VisitStatusRow(visit: active)
                }
            } else {
                Section("Current Visit") {
                    Text("No active visit")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Visit History") {
                if completedVisits.isEmpty {
                    Text("No completed visits yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(completedVisits) { visit in
                        VisitHistoryRow(visit: visit)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(place.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu("Export") {
                    Button("CSV (Excel-compatible)") {
                        exportCSV()
                    }
                    Button("PDF") {
                        exportPDF()
                    }
                }
            }

            ToolbarItem(placement: .cancellationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .alert("Exporting…", isPresented: $exportProgress != nil) {
            Button("OK", role: .cancel) {}
        }
    }

    private func exportCSV() {
        var allVisits = completedVisits
        if let active = activeVisit {
            allVisits.append(active)
        }
        let csv = ExportService.csvData(for: allVisits, places: [place])
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let url = directory.appendingPathComponent("office_visits_\(place.id.uuidString).csv")
        try? csv.data(using: .utf8)?.write(to: url)
        showExportNotification(for: url)
    }

    private func exportPDF() {
        var allVisits = completedVisits
        if let active = activeVisit {
            allVisits.append(active)
        }
        if let data = ExportService.pdfData(for: allVisits, places: [place]) {
            let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let url = directory.appendingPathComponent("office_visits_\(place.id.uuidString).pdf")
            try? data.write(to: url)
            showExportNotification(for: url)
        }
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

struct PlaceInfoRow: View {
    let label: String
    let value: String
    var format: Date.FormatStyle? = nil

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(format != nil ? format!.format(Date()) : value)
                .font(.caption)
        }
    }
}

struct VisitStatusRow: View {
    let visit: Visit

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Arrived")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(DateFormatter.localizedString(for: visit.arrivedAt, dateStyle: .medium, timeStyle: .medium))
                    .font(.caption)
            }
            if let leftAt = visit.leftAt {
                HStack {
                    Text("Departed")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(DateFormatter.localizedString(for: leftAt, dateStyle: .medium, timeStyle: .medium))
                        .font(.caption)
                }
            }
            HStack {
                Text("Duration")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(visit.durationSeconds.map { "\(Int($0 / 60)) min" } ?? "—")
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
}

struct VisitHistoryRow: View {
    let visit: Visit

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Arrived")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(DateFormatter.localizedString(for: visit.arrivedAt, dateStyle: .medium, timeStyle: .medium))
                    .font(.caption)
            }
            Spacer()
            if visit.leftAt != nil {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Departed")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(DateFormatter.localizedString(for: visit.leftAt!, dateStyle: .medium, timeStyle: .medium))
                        .font(.caption)
                }
            } else {
                Text("In Progress")
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
        }
    }
}

import Foundation
import SwiftData

@Model
final class Place {
    @Attribute(.unique) var id: UUID
    var name: String
    var latitude: Double
    var longitude: Double
    var label: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade) var visits: [Visit] = []

    init(name: String, latitude: Double, longitude: Double, label: String = "") {
        self.id = UUID()
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.label = label
        self.createdAt = Date()
    }
}

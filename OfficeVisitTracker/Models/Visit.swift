import Foundation
import SwiftData

@Model
final class Visit {
    enum Status {
        case active   // Arrived but hasn't left yet
        case completed // User has left the area
    }

    @Attribute(.unique) var id: UUID
    var placeId: UUID
    var arrivedAt: Date
    var leftAt: Date?
    var durationSeconds: Int?
    var status: Status

    init(placeId: UUID, arrivedAt: Date, status: Status = .active) {
        self.id = UUID()
        self.placeId = placeId
        self.arrivedAt = arrivedAt
        self.leftAt = nil
        self.durationSeconds = nil
        self.status = status
    }
}

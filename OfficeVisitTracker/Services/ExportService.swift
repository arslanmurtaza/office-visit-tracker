import Foundation
import SwiftData
import PDFKit
import UIKit

/// Generates CSV (Excel-compatible) and PDF exports of visit history.
struct ExportService {
    static let csvDelimiter = ","

    // MARK: - CSV (Excel-compatible)

    /// Produces UTF-8 CSV with a BOM so Excel opens it as Unicode.
    static func csvData(for visits: [Visit], places: [Place]) -> String {
        var lines = [
            "Place Name,Date Arrived,Date Departed,Duration (minutes),Duration (hours)"
        ]

        for visit in visits where visit.status == .completed {
            guard let place = places.first(where: { $0.id == visit.placeId }),
                  let leftAt = visit.leftAt,
                  let durationMinutes = visit.durationSeconds.map({ $0 / 60 }) else {
                continue
            }

            let placeName = place.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? place.name
            let arrived = ISO8601DateFormatter().string(from: visit.arrivedAt)
            let left = ISO8601DateFormatter().string(from: leftAt)

            lines.append("\(placeName),\(arrived),\(left),\(durationMinutes),\(durationMinutes / 60.0)")
        }

        return lines.joined(separator: "\n")
    }

    static func csvFileURL() -> URL {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return directory.appendingPathComponent("visits_\(timestamp).csv")
    }

    // MARK: - PDF

    static func pdfData(for visits: [Visit], places: [Place]) -> Data? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium

        let renderer = UIGraphicsPDFRenderer(bounds: PDFPageBounds)

        return renderer.pdfData { context in
            var y: CGFloat = 760

            // Title
            title.draw(at: CGPoint(x: 20, y: y))
            y -= 40

            // Table header
            let headerY = y
            drawTableRow(headers: headerRowTexts, at: CGPoint(x: 20, y: headerY), color: .systemBackground)
            y -= 44

            for visit in visits where visit.status == .completed {
                guard let place = places.first(where: { $0.id == visit.placeId }),
                      let leftAt = visit.leftAt,
                      let durationMinutes = visit.durationSeconds.map({ $0 / 60 }) else {
                    continue
                }

                let row = [
                    place.name,
                    dateFormatter.string(from: visit.arrivedAt),
                    dateFormatter.string(from: leftAt),
                    "\(durationMinutes)",
                    "\(durationMinutes / 60.0)"
                ]

                drawTableRow(headers: row, at: CGPoint(x: 20, y: y))
                y -= 32

                if y < 60 {
                    context.beginPage()
                    y = 760
                    title.draw(at: CGPoint(x: 20, y: y))
                    y -= 40
                    drawTableRow(headers: headerRowTexts, at: CGPoint(x: 20, y: y), color: .systemBackground)
                    y -= 44
                }
            }
        }
    }

    static func pdfFileURL() -> URL {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return directory.appendingPathComponent("visits_\(timestamp).pdf")
    }

    // MARK: - Drawing helpers

    private static let title: NSAttributedString = {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 22),
            .foregroundColor: UIColor.label,
        ]
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        attrs[.paragraphStyle] = paragraph
        return NSAttributedString(string: "Office Visit Log", attributes: attrs)
    }()

    private static let headerRowTexts = ["Place", "Arrived", "Departed", "Minutes", "Hours"]

    private static func drawTableRow(headers: [String], at point: CGPoint, color: UIColor = .label) {
        var x: CGFloat = point.x
        let y: CGFloat = point.y

        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 11),
            .foregroundColor: UIColor.white
        ]
        let paraStyle = NSMutableParagraphStyle()
        paraStyle.alignment = .center
        attributes[.paragraphStyle] = paraStyle

        for header in headers {
            let attr = NSAttributedString(string: header, attributes: attributes)
            attr.draw(at: CGPoint(x: x, y: y))
            x += attr.size().width + 12
        }
    }
}

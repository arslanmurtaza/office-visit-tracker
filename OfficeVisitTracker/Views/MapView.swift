import SwiftUI
import MapKit
import UIKit

/// A `MKMapView` wrapper with a long-press gesture recognizer for setting pins.
struct MapView: UIViewRepresentable {
    @Binding var pinCoordinate: CLLocationCoordinate2D?
    let onLongPress: (CLLocationCoordinate2D) -> Void

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.showsUserLocation = true
        mapView.mapType = .standard
        mapView.isPitchEnabled = false
        // Long-press gesture for dropping a pin
        let gesture = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.didLongPress(_:)))
        mapView.addGestureRecognizer(gesture)
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        if let coordinate = pinCoordinate {
            let region = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
            mapView.setRegion(region, animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        var parent: MapView
        init(_ parent: MapView) { self.parent = parent }

        @objc func didLongPress(_ gesture: UILongPressGestureRecognizer) {
            if gesture.state == .ended, let view = gesture.view {
                let point = gesture.location(in: view)
                if let coordinate = view.convert(point, toCoordinateFrom: view) {
                    parent.onLongPress(coordinate)
                }
            }
        }
    }
}

# Office Visit Tracker

An iOS app that tracks visits to office locations:
- **Add office locations** by dropping a pin on a map or searching for a place
- **Background tracking** — when you arrive at and leave an office, the visit timestamp and duration are recorded automatically, no need to open the app
- **Persistent local storage** — all data is stored on-device with SwiftData (encrypted at rest)
- **Export** — export visit history as **CSV** (opens in Excel) or **PDF**

## Requirements

- iOS 16.0+
- Xcode 16.0+
- A free Apple ID (for development on your own iPhone)
- A USB-C cable to connect your iPhone to your Mac

## How the architecture works

| Feature | Technology |
|---|---|
| Map + pin input | `MapKit` + `MapView` (UIViewRepresentable) |
| Background arrival/departure detection | `CLLocationManager` + `CLCircularRegion` region monitoring |
| Persistent storage | `SwiftData` (`Place`, `Visit` models) |
| PDF export | `UIGraphicsPDFRenderer` |
| Excel-compatible export | UTF-8 CSV with BOM |

## Prerequisites on your Mac

1. Install **Xcode** from the Mac App Store
2. Install the command-line tools:
   ```bash
   xcode-select --install
   ```
3. Open Xcode once to agree to the license
4. Sign in with your free Apple ID:
   - **Xcode** → **Settings** (⚙) → **Accounts** → **+** → Apple ID
   - Your free Apple ID allows development on your own iPhone
   - ⚠️ Apps expire after 7 days — rebuild periodically
   - Organizer → "Manage Development Profiles" to trust your device

## Build & run

1. Clone this repo onto your Mac:
   ```bash
   git clone <repo-url>
   cd office-visit-tracker
   ```

2. Open the project in Xcode:
   ```bash
   open OfficeVisitTracker.xcodeproj
   ```
   > ⚠️ **Important:** You must create the `.xcodeproj` file yourself, or use Xcode's "New Project" template and replace the contents of the default app folder with the files from this repo.

3. Connect your iPhone via USB-C and trust the computer:
   - On your iPhone: **Settings → General → VPN & Device Management** → tap your certificate → **Trust**

4. In Xcode:
   - Select your iPhone as the run destination (top-left dropdown)
   - Ensure the team is set to your Apple ID in **Signing & Capabilities**
   - Check **Background Modes → Location updates**

5. Press **Cmd+R** to build and run

## How it works

1. **Add an office**: Tap the `+` button, drop a pin on the map, or search for a place. The app saves it and starts monitoring the region (~100 m radius).

2. **Background tracking**: When your iPhone crosses the office boundary, iOS wakes the app. The app records a `Visit` with an `arrivedAt` timestamp and continues monitoring. When you leave, it records `leftAt` and computes the duration.

3. **View history**: Tap any office in the list to see its visit history and export options.

4. **Export**: From the detail view's Share menu, export as CSV (Excel-compatible) or PDF.

## Project structure

```
OfficeVisitTracker/
├── App.swift                    # App entry point + SwiftData container
├── Info.plist                   # Location permissions (Always) + Background Modes
├── Models/
│   ├── Place.swift              # Office location model
│   └── Visit.swift              # Visit record (arrived, departed, duration)
├── Views/
│   ├── HomeView.swift           # List of offices
│   ├── AddPlaceView.swift       # Add office via search or map pin
│   ├── PlaceDetailView.swift    # Visit history + export
│   └── MapView.swift            # Map with long-press pin placement
├── Services/
│   ├── LocationService.swift    # Core Location + region monitoring
│   └── ExportService.swift      # PDF + CSV export
└── Resources/
    ├── LaunchScreen.storyboard
    └── Assets.swift
```

## Known limitations

- **3-device limit** with the free Apple ID; apps expire after 7 days
- **Background location** is rate-limited by iOS to save battery — detection is approximate (~100 m region radius)
- **Cost:** $0 (free, using a free Apple ID). Upgrade to the Apple Developer Program ($99/year) for unlimited devices and no 7-day expiry

## Next steps

- Add cloud sync (CloudKit) for visits across devices
- Add timezone-aware duration calculation
- Add local notifications for "you left the office" reminders

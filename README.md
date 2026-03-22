# Delivery Driver — iOS App

A mobile application for delivery drivers built with SwiftUI and Swift. Covers the full delivery workflow: manifest management, parcel scanning, proof-of-delivery capture, real-time location tracking, and offline-resilient data sync.

UI/UX follows a Strava-inspired design language — bold typography, high contrast, status-driven colour coding.

---

## Requirements

| Dependency | Version |
|---|---|
| Xcode | 15+ |
| iOS deployment target | 16.0+ |
| [XcodeGen](https://github.com/yonaskolb/XcodeGen) | Any recent version |
| macOS | 13 Ventura+ |

Install XcodeGen if you don't already have it:

```bash
brew install xcodegen
```

---

## Getting started

```bash
# 1. Clone the repo
git clone git@github.com:nichom01/delivery-app.git
cd delivery-app

# 2. Generate the Xcode project
xcodegen generate

# 3. Build and launch in the simulator
bash run.sh
```

`run.sh` handles everything in one go: boots the iPhone 15 Pro simulator, builds the app, installs it, and streams console output to your terminal.

To open in Xcode instead:

```bash
xcodegen generate
open DeliveryDriver.xcodeproj
```

> **Note:** The `.xcodeproj` is not committed to the repo. Always run `xcodegen generate` after cloning or pulling changes to `project.yml`.

---

## First run — Demo Mode

The app requires API endpoints to be configured before a real login will work. To explore the UI immediately, tap **Try Demo Mode** on the login screen. This:

- Bypasses the API and stores a local session token
- Seeds 5 realistic deliveries into the local store
- Lets you exercise every screen end-to-end

---

## Configuration

All API endpoints and service settings are configured inside the app on the **Settings tab** (gear icon). No rebuild is required — changes take effect immediately.

### API Endpoints

| Setting | Description |
|---|---|
| **Login** | `POST` — authenticates the driver and returns a session token |
| **Load** | `POST` — receives scanned barcode/label data |
| **Manifest** | `GET` — returns the list of deliveries assigned to the driver |
| **Submission** | `POST` — receives POD, delivery status updates, and location pings |

Enter the full URL for each endpoint, e.g. `https://api.example.com/v1/login`.

### Authentication

All requests (except login) include the session token as a Bearer token:

```
Authorization: Bearer <token>
```

The token is expected to be returned in the login response as:

```json
{ "token": "<session-token>" }
```

Tokens are stored in the iOS Keychain — never in plaintext.

### Manifest response format

The manifest endpoint must return either a bare JSON array or a wrapped object:

```json
// Bare array
[
  {
    "delivery_id": "DEL-001",
    "recipient_name": "Sarah Mitchell",
    "address_line_1": "14 Oakwood Avenue",
    "address_line_2": null,
    "city": "Manchester",
    "postcode": "M14 5EW",
    "box_count": 3,
    "total_weight_kg": 12.4,
    "special_instructions": null,
    "status": "pending"
  }
]

// Or wrapped
{ "deliveries": [ ... ] }
```

Valid `status` values: `pending`, `completed`, `failed`.

### Location & sync settings

| Setting | Default | Description |
|---|---|---|
| Location capture enabled | On | Toggle GPS tracking on/off |
| Location capture frequency | 30 s | How often a location point is recorded |
| Data transmission enabled | On | Toggle automatic background sync on/off |
| Data transmission frequency | 60 s | How often queued records are flushed to the backend |

---

## Architecture

```
MVVM + Service layer
```

| Layer | Responsibility |
|---|---|
| **Views** | SwiftUI screens and reusable components |
| **ViewModels** | `@MainActor ObservableObject` — drives view state, calls services |
| **Services** | `APIClient`, `KeychainService`, `LocationService`, `SyncService`, `SettingsStore` |
| **Persistence** | Core Data via `PersistenceController`; all writes use background contexts |

### Offline-first data flow

1. Every data capture (scan, POD, location) is written to Core Data **before** any network attempt.
2. `SyncService` runs on a configurable timer, finds records with `submittedAt == nil`, and POSTs them to the backend.
3. On a successful response it stamps `submittedAt` on the record.
4. Failed transmissions are retried automatically on the next cycle.
5. The **Audit** tab surfaces every record with its transmission status.

### Background location

- `CLLocationManager` runs with `allowsBackgroundLocationUpdates = true` and the `location` Background Mode capability.
- When the app enters the background, `startMonitoringSignificantLocationChanges()` is activated as a safety net — if the OS terminates the app, this will relaunch it and full tracking resumes.
- Location points are recorded at the configured frequency using a timer in foreground and a time-gate in the delegate callback in background.

---

## Project structure

```
delivery-app/
├── project.yml                          # XcodeGen spec
├── run.sh                               # One-command simulator launcher
├── docs/
│   └── delivery_app_prd.md              # Product requirements document
└── DeliveryDriver/
    ├── App/
    │   ├── DeliveryDriverApp.swift      # Entry point, scenePhase lifecycle
    │   └── AppState.swift               # Top-level routing (splash/login/main)
    ├── Models/
    │   ├── DeliveryDriver.xcdatamodeld  # Core Data schema (5 entities)
    │   └── ManifestModels.swift         # Codable structs for manifest JSON
    ├── Persistence/
    │   └── PersistenceController.swift  # Core Data stack + 14-day purge
    ├── Services/
    │   ├── APIClient.swift              # async/throws network layer
    │   ├── KeychainService.swift        # Session token read/write/delete
    │   ├── LocationService.swift        # GPS tracking + background lifecycle
    │   ├── SettingsStore.swift          # UserDefaults-backed config singleton
    │   ├── SyncService.swift            # Timer-driven offline sync
    │   └── DemoDataService.swift        # Seeds mock data for demo mode
    ├── ViewModels/
    │   ├── LoginViewModel.swift
    │   ├── ManifestViewModel.swift
    │   ├── LoadViewModel.swift
    │   ├── PODViewModel.swift
    │   └── AuditViewModel.swift
    ├── Views/
    │   ├── RootView.swift               # Route switcher
    │   ├── SplashView.swift
    │   ├── LoginView.swift
    │   ├── MainTabView.swift            # Tab bar + shared top nav
    │   ├── Components/                  # StatusBadge, EmptyStateView,
    │   │                                #   DDTextField, ProfileSheet
    │   ├── Manifest/                    # ManifestView, DeliveryDetailView
    │   ├── Load/                        # LoadView, BarcodeScannerView
    │   ├── POD/                         # PODView, SignatureCanvasView
    │   ├── Audit/                       # AuditView
    │   └── Settings/                    # SettingsView
    └── Utilities/
        └── DesignSystem.swift           # Colours, typography, modifiers
```

---

## Data schema

| Entity | Key fields |
|---|---|
| `ManifestEntity` | `manifestId`, `downloadedAt`, `rawData`, `status` |
| `DeliveryEntity` | `deliveryId`, `manifestId`, `recipientName`, `address*`, `boxCount`, `weightKg`, `instructions`, `status` |
| `ScanEntity` | `scanId`, `barcodeValue`, `deliveryId`, `scannedAt`, `submittedAt?` |
| `PODEntity` | `podId`, `deliveryId`, `recipientName`, `signatureImage`, `capturedAt`, `submittedAt?` |
| `LocationEntity` | `locationId`, `latitude`, `longitude`, `recordedAt`, `submittedAt?` |

Audit records (Scan, POD, Location) are automatically purged after **14 days** on each app launch.

---

## Permissions

The app requests two permissions at runtime:

| Permission | Why |
|---|---|
| **Camera** | Barcode/QR scanning on the Load screen |
| **Location — Always** | Background GPS tracking during deliveries |

Location permission must be granted as **Always** (not just While Using) for background tracking to function correctly.

---

## Simulator notes

- The **camera scanner** is not available in the simulator. Use the **"Enter barcode manually"** fallback on the Load screen.
- Location simulation: in the simulator, go to **Features → Location** and choose a preset or custom location to generate location events.
- Demo mode seeds the local store directly so no network connectivity is needed.

---

## Out of scope (v1)

- Android support
- Multi-driver / team management
- In-app navigation or mapping
- Biometric login
- Push notifications

## Completed post-v1 features

| Feature | Branch | PR |
|---|---|---|
| Photo capture at POD | `feature/pod-photo-capture` | [#1](https://github.com/nichom01/delivery-app/pull/1) |

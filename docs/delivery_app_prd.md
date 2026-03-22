# Product Requirements Document
## iOS Delivery Driver Application
**Version:** 1.0  
**Platform:** iOS (iPhone)  
**Language:** Swift  
**Date:** March 2026  

---

## 1. Overview

A mobile application for delivery drivers that enables manifest management, proof of delivery capture, real-time location tracking, and offline-resilient data synchronisation with a backend service. The UI/UX should follow the style and design language of Strava — clean, bold, activity-focused, and data-driven.

---

## 2. Goals & Objectives

- Provide drivers with a streamlined tool to manage daily deliveries from load to proof of delivery
- Ensure data integrity through local persistence when connectivity is unavailable
- Enable operations teams to track driver location and delivery status in real time
- Support configurable sync and location tracking frequency via in-app settings

---

## 3. Navigation Structure

### Bottom Tab Bar
| Position | Tab | Icon |
|----------|-----|------|
| 1 | Load | Barcode/camera icon |
| 2 | Manifest | List icon |
| 3 | Audit | Clock/history icon |
| 4 | Settings | Gear icon |

### Top Navigation Bar
- **Left:** App logo / page title
- **Right:** Profile avatar icon — tapping opens a profile sheet with a **Sign Out** option that returns the user to the Login screen

---

## 4. Screens & Functional Requirements

---

### 4.1 Splash Screen

**Purpose:** Initial branded loading screen shown on app launch.

**Requirements:**
- Display app logo and name
- Show a loading indicator while the app initialises
- Automatically navigate to Login if no valid session exists, or to the last active tab if a session is present
- Duration: no longer than 2 seconds unless data is loading

---

### 4.2 Login Screen

**Purpose:** Authenticate the driver before accessing the app.

**Requirements:**
- Fields: Username, Password
- Primary CTA: **Log In** button
- On success: navigate to the Load tab (bottom tab position 1)
- On failure: display an inline error message
- Credentials submitted to the API endpoint configured in Settings (`api_endpoint_login`)
- No biometric/SSO requirement in v1

---

### 4.3 Load Screen

**Purpose:** Allow the driver to scan a box label using the device camera to register a load.

**Guard condition:** If no manifest has been downloaded, redirect to the Manifest screen and display the message:  
> *"No manifest has been downloaded. Please download a manifest before loading."*

**Requirements:**
- Camera view with barcode/QR scanning capability (using AVFoundation)
- On successful scan: extract box/label data and associate it with the active manifest
- Scanned data is written to local store with a timestamp
- Display confirmation of successful scan with box details
- Support manual entry as a fallback if camera is unavailable

**Data captured (stored locally with timestamp):**
- Box label / barcode value
- Scan timestamp
- Associated manifest/consignment reference

---

### 4.4 Manifest Screen

**Purpose:** Download and display the list of deliveries assigned to the driver.

**Requirements:**
- **Download button** to fetch the manifest from `api_url_manifest`
- Display a list of deliveries, each showing:
  - Consignment/delivery reference
  - Recipient name
  - Delivery address (summary)
  - Number of boxes
  - Status (pending / completed)
- Tap a delivery to drill down to the **Delivery Screen**
- Pull-to-refresh to re-download the manifest
- Downloaded manifest is persisted locally for offline use
- Show last downloaded timestamp

---

### 4.5 Delivery Screen

**Purpose:** Display full consignment details for a single delivery.

**Requirements:**
- Display:
  - Recipient name
  - Full delivery address
  - Number of boxes
  - Total weight
  - Special instructions (if any)
  - Current status
- Primary CTA: **Capture POD** button — navigates to the POD Screen
- Back navigation returns to the Manifest list

---

### 4.6 POD (Proof of Delivery) Screen

**Purpose:** Capture a signature as proof of delivery.

**Requirements:**
- Signature capture canvas (finger-drawn)
- Pre-populated name field defaulting to the recipient's name (editable)
- **Clear** button to reset the signature
- **Submit** button to save the POD
- On submission:
  - POD data (signature image + name + timestamp) written to local store
  - Delivery status updated to "completed"
  - Data queued for transmission to `api_endpoint_submission`
- If API is unavailable, data is persisted locally and retried per the configured transmission frequency

**Data captured (stored locally with timestamp):**
- Signature image (PNG)
- Recipient name
- Delivery / consignment reference
- Submission timestamp

---

### 4.7 Settings Screen

**Purpose:** Configure application behaviour and API endpoints.

**Requirements:**

| Setting | Type | Description |
|---------|------|-------------|
| Location capture frequency | Integer (seconds) | How often the device location is recorded |
| Location capture enabled | Toggle | Enable / disable location tracking |
| Data transmission frequency | Integer (seconds) | How often queued data is sent to the backend |
| Data transmission enabled | Toggle | Enable / disable automatic data sync |
| API Endpoint – Login | Text field | URL for authentication |
| API URL – Load | Text field | URL for load/scan data submission |
| API URL – Manifest | Text field | URL for manifest download |
| API Endpoint – Submission | Text field | URL for delivery, POD, and location data |

- Settings persisted locally using `UserDefaults` or equivalent
- Changes take effect immediately (no app restart required)

---

### 4.8 Audit Screen

**Purpose:** Provide a transparent log of all data recorded by the app and its transmission status.

**Requirements:**
- List of all data events recorded locally, showing:
  - Event type (Scan / POD / Location)
  - Summary description
  - Recorded timestamp
  - Transmission status: **Sent** (with sent timestamp) or **Pending**
- Sorted by most recent first
- Filter options: All / Pending / Sent
- Read-only — no editing of audit records

---

## 5. Background Services

### 5.1 Location Tracking Service

- Runs as a background service using Core Location with the **Always** location permission
- Must continue recording location when the app is backgrounded or the screen is locked — use `allowsBackgroundLocationUpdates = true` and enable the Background Modes capability (`location` mode) in the app entitlements
- In the event the app is terminated by the OS, significant location change monitoring (`startMonitoringSignificantLocationChanges`) should be used to relaunch the app and resume full tracking
- Records device GPS coordinates at the frequency configured in Settings
- Each location record stored locally with a timestamp
- Enabled / disabled via Settings toggle
- Location data queued for transmission to `api_endpoint_submission`

### 5.2 Data Transmission Service

- Runs on a configurable timer (frequency set in Settings)
- Scans local store for any unsubmitted records (scans, PODs, location data)
- Attempts to POST data to the relevant API endpoint
- On success: marks records as sent and records the sent timestamp in the Audit log
- On failure (no connectivity / endpoint unavailable): records remain in local store and are retried on the next transmission cycle
- Can be enabled / disabled via Settings toggle

---

## 6. Data & Local Persistence

All data captured in the app must be written to a local persistent store (e.g. Core Data or SQLite) before any network attempt is made. This ensures no data is lost in the event of connectivity issues.

Audit log records (scan events, POD records, location entries) must be automatically purged from the local store after **14 days** to manage device storage. A background cleanup task should run on app launch to remove expired records.

### Local Data Schema (Summary)

**Manifest**
- manifest_id, downloaded_at, raw_data (JSON), status

**Delivery**
- delivery_id, manifest_id, recipient_name, address, box_count, weight, instructions, status

**Scan**
- scan_id, barcode_value, delivery_id, scanned_at, submitted_at (nullable)

**POD**
- pod_id, delivery_id, recipient_name, signature_image (binary), captured_at, submitted_at (nullable)

**Location**
- location_id, latitude, longitude, recorded_at, submitted_at (nullable)

---

## 7. API Endpoints (Configured via Settings)

| Endpoint Setting | Method | Purpose |
|------------------|--------|---------|
| `api_endpoint_login` | POST | Authenticate user, return session token |
| `api_url_load` | POST | Submit scanned box/label data |
| `api_url_manifest` | GET | Download manifest/delivery list |
| `api_endpoint_submission` | POST | Submit POD, delivery updates, and location data |

All requests should include the session token in the Authorization header.  
All responses should be handled gracefully — errors must not crash the app and must be logged in the Audit trail.

---

## 8. Design & UX Guidelines

- **Style:** Strava-inspired — bold typography, high contrast, strong use of colour to indicate status, card-based layouts
- **Colour palette:** Dark primary brand colour with bright accent (e.g. orange or green) for CTAs and active states
- **Typography:** Bold headers, clean body text — SF Pro recommended
- **Status indicators:** Use colour-coded badges/chips (e.g. green = completed, amber = pending, red = failed)
- **Empty states:** All list screens must show a meaningful empty state message with a clear CTA
- **Loading states:** All network operations must show a loading indicator
- **Error handling:** User-friendly inline error messages for all failure scenarios

---

## 9. Non-Functional Requirements

| Requirement | Detail |
|-------------|--------|
| Platform | iOS 16+ |
| Language | Swift (UIKit or SwiftUI) |
| Offline support | Full local persistence; app must be usable without connectivity |
| Security | Session token stored in Keychain; no plaintext credential storage |
| Permissions | Camera (scanning), Location — **Always** permission required for background tracking |
| Performance | App launch < 2s; list screens load < 1s from local store |
| Audit log retention | Local audit records purged after **14 days** |
| Delivery volume | **25–50 deliveries per driver per day** — local store and list UI must handle this comfortably |
| Background location | App must continue tracking location when backgrounded or terminated |

---

## 10. Out of Scope (v1)

- Android support
- Multi-driver / team management
- In-app navigation / mapping
- Photo capture at POD (signature only)
- Biometric login
- Push notifications

---

## 11. Manifest Schema

The manifest uses a fixed schema. The following fields are expected per delivery record returned from `api_url_manifest`:

| Field | Type | Description |
|-------|------|-------------|
| `delivery_id` | String | Unique delivery reference |
| `recipient_name` | String | Name of the recipient |
| `address_line_1` | String | First line of delivery address |
| `address_line_2` | String | Second line (optional) |
| `city` | String | City |
| `postcode` | String | Postcode |
| `box_count` | Integer | Number of boxes for this delivery |
| `total_weight_kg` | Decimal | Total weight in kilograms |
| `special_instructions` | String | Optional delivery notes |
| `status` | String | e.g. `pending`, `completed`, `failed` |

> ⚠️ The manifest schema should be version-controlled. Any future changes to field names or types must be coordinated with the mobile team to avoid parsing failures.

---

## 12. Open Questions

1. What authentication token format is used — JWT or session cookie?

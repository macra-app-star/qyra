# Qyra Architecture

## Overview
Qyra is a premium-only iOS macro tracking app with AI intelligence. Built with SwiftUI, SwiftData, and Supabase.

- **Platforms:** iOS 17+ (primary), watchOS 10+, WidgetKit, ActivityKit, AppIntents
- **Language:** Swift 5.9+
- **UI Framework:** SwiftUI (dark mode only, monochrome aesthetic)
- **Architecture:** Strict MVVM with protocol-based dependency injection
- **Backend:** Supabase (Auth, Postgres + RLS, Realtime, Edge Functions)
- **Payments:** StoreKit 2 (premium-only, no free tier)
- **Persistence:** SwiftData (offline-first) with cloud sync

## Architecture Decision Records

### ADR-001: SwiftData over Core Data
- **Decision:** Use SwiftData with `@Model` macro
- **Rationale:** iOS 17+ target allows it. Cleaner API, native SwiftUI integration via `@Query`, less boilerplate than Core Data.
- **Risk:** Less mature. Mitigated by keeping models simple and writing integration tests.
- **Fallback:** Can migrate to Core Data if SwiftData proves unstable.

### ADR-002: Supabase over Firebase
- **Decision:** Use Supabase for all backend services
- **Rationale:** Open-source Postgres with proper SQL, migrations as code, Row Level Security, Edge Functions in TypeScript, self-hostable. Previous Firebase iteration had schema limitations.
- **Migration:** Existing Firebase data (9 entries) will be imported via a one-time migration.

### ADR-003: @Observable over ObservableObject/Combine
- **Decision:** Use `@Observable` macro (Observation framework) for all ViewModels
- **Rationale:** iOS 17+ target. Finer-grained observation (only re-renders views that read changed properties). Better performance than `@Published`.
- **Pattern:** ViewModels are `@Observable class`, Views use `@State` for local state.

### ADR-004: No Third-Party UI Libraries
- **Decision:** All UI components are hand-built in SwiftUI
- **Rationale:** Monochrome Apple/Tesla aesthetic requires precise control. Third-party libraries add visual inconsistency and binary size.

### ADR-005: App Group for Widget Data
- **Container ID:** `group.co.tamras.qyra`
- **Usage:** Main app writes daily macro totals to shared UserDefaults/SwiftData. Widgets read from shared container.

### ADR-006: Offline-First with Last-Write-Wins Sync
- **Decision:** All data writes go to SwiftData first, then sync to Supabase
- **Conflict Resolution:** Last-write-wins using server `updated_at` timestamps
- **Queue:** `SyncRecord` model tracks pending operations (insert/update/delete)
- **Triggers:** App foreground, network change, 15-minute timer, BackgroundTasks

## Layer Diagram

```
UI Layer (SwiftUI Views)
    |
    v
ViewModel Layer (@Observable, @MainActor)
    |
    v
Domain Layer (UseCases, Models - pure Swift)
    |
    v
Data Layer
  |-- Local (SwiftData Repositories)
  |-- Remote (Supabase Client)
  |-- Sync (SyncEngine, ConflictResolver)
    |
    v
Services Layer (HealthKit, StoreKit, Camera, Speech, Barcode)
```

## Bundle & Entitlements
- **Bundle ID:** `co.tamras.qyra`
- **App Group:** `group.co.tamras.qyra`
- **Entitlements:** HealthKit, Sign in with Apple, In-App Purchases, App Groups

## Performance Targets
- 120 fps UI
- < 200ms p95 UI interaction latency
- < 3s p95 AI response latency
- No main thread blocking
- Memory optimized for baseline iPhone

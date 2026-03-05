# MACRA — Product Roadmap

## v1.0 (Launch) ✅
- Manual meal entry with full macro breakdown
- Personalized onboarding with Mifflin-St Jeor calculation
- Animated macro progress rings
- Weekly insights (bar chart, streaks, averages)
- Apple Health integration (steps, active calories)
- Goal editor
- Meal detail view with add/delete items
- StoreKit 2 paywall (monthly/annual)
- Privacy-first on-device storage
- Monochrome dark mode design system

---

## v1.1 — Barcode & Search (Target: 4-6 weeks post-launch)

### Barcode Scanning
- Integrate OpenFoodFacts API (free, open-source nutrition database)
- AVCaptureSession barcode scanner using device camera
- Auto-populate food name + macros from barcode lookup
- Manual correction flow if data is inaccurate
- Offline cache of recently scanned items

### Food Search
- Searchable food database powered by OpenFoodFacts
- Recent searches and favorites
- Quick re-log: tap a previous meal to log it again
- Suggested foods based on time of day

### Technical
- `MACRA/Services/FoodDatabaseService.swift` — API client for OpenFoodFacts
- `MACRA/UI/Scanner/BarcodeScannerView.swift` — Camera preview + scanner
- `MACRA/UI/Logging/FoodSearchView.swift` — Search interface
- `MACRA/Data/Local/FoodCacheRepository.swift` — Offline barcode cache

---

## v1.2 — AI Camera Recognition (Target: 8-10 weeks)

### Photo-Based Food Logging
- Take a photo of your meal → AI identifies foods and estimates macros
- Use on-device Core ML model for basic food classification
- Optional cloud API for more accurate recognition
- User confirmation step before logging (never auto-log)
- Save recognized items for faster future logging

### Technical
- `MACRA/Services/FoodRecognitionService.swift` — Core ML + optional API
- `MACRA/UI/Camera/CameraCaptureView.swift` — Photo capture
- `MACRA/UI/Camera/FoodConfirmationView.swift` — Review + edit before saving

---

## v1.3 — Voice Logging (Target: 12-14 weeks)

### Voice-Based Meal Entry
- "I had two eggs and toast with butter for breakfast"
- Speech-to-text via iOS Speech framework
- NLP parsing to extract food items + estimated macros
- Confirmation step with editable fields
- Works offline for transcription, optional cloud for NLP

### Technical
- `MACRA/Services/VoiceTranscriptionService.swift` — SFSpeechRecognizer
- `MACRA/Services/MealParsingService.swift` — Text → food items
- `MACRA/UI/Voice/VoiceLogView.swift` — Recording interface

---

## v1.4 — Social & Challenges (Target: 16-20 weeks)

### Social Features (Requires Backend)
- User accounts via Sign in with Apple
- Supabase backend for cloud sync + social
- Friend system with privacy controls
- Weekly leaderboards (opt-in)
- Group challenges (e.g., "Hit protein goal 5/7 days")
- Activity feed showing friends' streaks (not their food)

### Backend Architecture
- Supabase project with Row Level Security
- Real-time sync via SyncEngine (already scaffolded)
- Edge Functions for leaderboard calculation
- Push notifications for challenges

---

## v1.5 — Apple Watch (Target: 24+ weeks)

### watchOS Companion
- Quick meal logging from wrist
- Today's macro rings as complications
- Step count display
- Haptic reminders for meal logging
- WatchConnectivity for instant data sync

---

## v2.0 — Intelligence Layer

### Adaptive Goals
- Adjust macro targets based on adherence history
- Suggestions when consistently over/under on a macro
- Weekly AI summary of nutrition patterns
- Plateau detection and goal adjustment recommendations

### Meal Planning
- Suggest meals to hit remaining daily macros
- Recipe suggestions based on available macros budget
- Meal prep planning for the week ahead

---

## Pricing Evolution

| Version | Monthly | Annual | Notes |
|---------|---------|--------|-------|
| v1.0 | $9.99 | $79.99 | Launch pricing |
| v1.2+ | $12.99 | $99.99 | After AI features ship |
| v2.0+ | Consider tiered pricing | | Free tier with basic tracking |

---

## Metrics to Track

- Daily Active Users (DAU)
- Meals logged per user per day
- Subscription conversion rate (free trial → paid)
- Retention: Day 1, Day 7, Day 30
- Feature adoption: % using HealthKit, % using insights, % editing goals
- App Store rating trend
- Crash-free rate (target: 99.9%+)
- Average session duration

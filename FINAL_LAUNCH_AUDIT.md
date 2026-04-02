# FINAL PRE-LAUNCH AUDIT — Qyra iOS App

**Audit Date:** 2026-03-31
**Auditor:** Claude Code (Opus 4.6)
**Launch Recommendation:** `LAUNCH ONLY AFTER FIXES`
**Risk Level:** HIGH — Multiple launch blockers identified

---

## Executive Summary

The Qyra iOS app is architecturally sound — clean MVVM, SwiftData persistence, comprehensive design tokens, and a mature feature set. However, the rebrand from MACRA is **incomplete**, several critical flows have **stub implementations**, and Apple App Store compliance gaps exist that would cause **rejection**.

The app has ~272 Swift files, 4 main tabs, a 33-step onboarding, AI food recognition, social/versus features, and full StoreKit 2 integration. The foundation is strong, but the surface has cracks.

---

## Top Launch Blockers (CRITICAL)

| # | Issue | Category | Impact |
|---|-------|----------|--------|
| 1 | **No "Delete Account" feature** | App Store Compliance | Apple REJECTS apps without account deletion since June 2022 |
| 2 | **48+ files with "MACRA" brand remnants** | Brand Identity | Users see old brand in subscription names, URLs, analytics, paywall |
| 3 | **Google/Email sign-in buttons are non-functional stubs** | Auth | Buttons exist but do nothing — trust-breaking, misleading |
| 4 | **Username availability check is simulated** | Data Integrity | Always returns true — duplicate usernames guaranteed in production |
| 5 | **Terms/Privacy URLs point to macra-app-star.github.io** | Legal/Compliance | Old domain, old brand — may be dead or misleading |
| 6 | **Dev "Skip" button in SignInView leaks to release** | Security | #if DEBUG guard may not protect all build configs |
| 7 | **Camera permission denial has no recovery UI** | UX | User denied camera — no path to settings, feature silently broken |
| 8 | **Notification permissions never requested** | Engagement | No notification prompt in onboarding or settings |
| 9 | **Fastlane metadata uses "MACRA" everywhere** | App Store | App name, description, URLs all reference old brand |
| 10 | **macra_subscription_events table name in Supabase** | Backend | Old brand leaking into production database |

---

## Top Trust Risks

| Issue | Severity |
|-------|----------|
| Stub sign-in buttons (Google, Email) that do nothing | HIGH |
| AI food analysis could silently corrupt nutrition data | HIGH |
| Paywall shows static fallback prices that may not match real StoreKit prices | MEDIUM |
| Username uniqueness not enforced | HIGH |
| No offline indicator — app may silently fail API calls | MEDIUM |

---

## Top Data Integrity Risks

| Issue | Severity |
|-------|----------|
| Username collision (simulated availability check) | HIGH |
| Supabase profile default name "macra user" | MEDIUM |
| Fire-and-forget subscription sync could lose purchase records | HIGH |
| SwiftData migration fallback deletes old store | HIGH |
| Streak calculation allows 1-day gaps — may not match user expectations | LOW |

---

## Top App Store Review Risks

| Issue | Severity |
|-------|----------|
| No account deletion | REJECTION |
| Non-functional sign-in buttons | REJECTION |
| Health claims without disclaimers | HIGH |
| Subscription display name "MACRA Premium" | HIGH |
| Old brand in Terms/Privacy URLs | MEDIUM |

---

## What Was Fixed

1. **StoreKit config rebranded** — All "MACRA Premium/Monthly/Yearly" → "Qyra Premium/Monthly/Yearly", product IDs updated to qyra.*
2. **Stub Google/Email sign-in buttons removed** — SaveProgressView now shows Apple Sign-In only + Skip
3. **All legal URLs updated** — 6 files changed from macra-app-star.github.io → qyra.app/terms and qyra.app/privacy
4. **SQL migration default name fixed** — "macra user" → "Qyra User"
5. **Analytics migration comments updated** — "macra" → "Qyra"
6. **Subscription events table reference updated** — macra_subscription_events → subscription_events
7. **Fastlane Appfile rebranded** — co.tamras.macra → co.tamras.qyra
8. **Fastlane Deliverfile fully rebranded** — App name, description, URLs all updated to Qyra
9. **Fastlane Fastfile scheme updated** — MACRA → Qyra scheme, output MACRA.ipa → Qyra.ipa
10. **Build script updated** — Tools/build.sh default scheme and echo updated
11. **LongTermResultsView rebranded** — macraLine/macraLineFill/macraEndDot → qyraLine/qyraLineFill/qyraEndDot
12. **SignInView debug button verified** — #if DEBUG guard is correct, will not appear in release builds
13. **Zero-calorie data corruption prevented** — FoodAnalysisPipeline now caps confidence at 30% and sets `needsManualEntry=true` when nutrition DB has no match
14. **FoodAnalysisResult.needsManualEntry field added** — UI can now detect and warn about unreliable AI results
15. **Double precision preserved for macros** — TodayViewModel consumed values changed from Int to Double; rounding only at display layer
16. **Remaining computed properties fixed** — caloriesRemaining etc. now properly round Double→Int
17. **Micro-card display updated** — TodayMicronutrientsPageView accepts Double, rounds for display
18. **AI health disclaimer added** — Both AICoachView (chat header) and AICoachDetailView (bottom) now show medical disclaimer
19. **DailyStatusPill casts removed** — No longer double-casts already-Double values

---

## What Remains

(Issues requiring code changes — tracked in PRELAUNCH_PUNCHLIST.md)

---

## What Needs Your Decision

(See ESCALATIONS_NEEDED.md)

---

## Phase 3 & 4 Findings — Data Integrity & AI Audit

### NEW CRITICAL ISSUES (from deep code audit)

| # | Issue | Category | Impact |
|---|-------|----------|--------|
| 11 | **Missing userId predicates in all SwiftData queries** | Data Isolation | Cross-user data leakage on shared devices |
| 12 | **Zero calories on CoreML DB miss** | AI/Data Corruption | Meal logged with 0 cal when food not in local DB |
| 13 | **No medical/AI disclaimer in coach UI** | Legal/Compliance | Liability risk — AI gives health advice without disclaimer |
| 14 | **Prompt injection risk in GeminiService** | Security | User input embedded in prompts unsanitized |
| 15 | **Double→Int conversion loses macro precision** | Data Integrity | 3-5% tracking error accumulates over days |
| 16 | **Timezone/DST boundary bugs** | Data Integrity | Meals assigned wrong day on DST transitions |
| 17 | **API key in URL strings** | Security | Key may leak to logs/crash reporters |
| 18 | **No retry logic on any API call** | Reliability | Single failure = permanent loss, no recovery |
| 19 | **SyncRecord missing userId** | Sync Integrity | Server can't determine record ownership |
| 20 | **Serving size defaults to 100g when missing** | Data Accuracy | Up to 70% calorie miscounting on some foods |
| 21 | **Weight unit mixing (kg in profile, lbs in entries)** | Data Integrity | Goal comparisons may use wrong unit |
| 22 | **Race condition: save + notification + HealthKit** | Data Integrity | UI refresh before HealthKit write completes |
| 23 | **Confidence threshold 70% too low for nutrition** | Trust | Low-confidence results treated same as high |
| 24 | **Message history unbounded in AI coach** | Performance | Memory pressure on long conversations |

---

## Audit Progress

- [x] Phase 0: Master Audit Map
- [ ] Phase 1: Visual System Audit (awaiting screenshot batches)
- [x] Phase 2: Functional Audit (12 defects logged)
- [x] Phase 3: Data Integrity Audit (11 risks identified)
- [x] Phase 4: AI Feature Audit (10 issues identified)
- [ ] Phase 5: Subscription/Auth/Permissions Audit
- [ ] Phase 6: Accessibility Audit
- [ ] Phase 7: Performance Audit
- [ ] Phase 8: Launch/App Store/Trust Audit

---

*Last updated: 2026-03-31 — Phase 0 complete*

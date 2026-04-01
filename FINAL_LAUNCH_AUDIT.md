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

(Fixes applied during this audit — updated as work progresses)

---

## What Remains

(Issues requiring code changes — tracked in PRELAUNCH_PUNCHLIST.md)

---

## What Needs Your Decision

(See ESCALATIONS_NEEDED.md)

---

## Audit Progress

- [x] Phase 0: Master Audit Map
- [ ] Phase 1: Visual System Audit (awaiting screenshot batches)
- [ ] Phase 2: Functional Audit
- [ ] Phase 3: Data Integrity Audit
- [ ] Phase 4: AI Feature Audit
- [ ] Phase 5: Subscription/Auth/Permissions Audit
- [ ] Phase 6: Accessibility Audit
- [ ] Phase 7: Performance Audit
- [ ] Phase 8: Launch/App Store/Trust Audit

---

*Last updated: 2026-03-31 — Phase 0 complete*

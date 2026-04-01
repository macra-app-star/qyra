# FUNCTIONAL DEFECT LOG

---

## Defects Found During Code Audit

| # | Feature | Reproduction Path | Expected | Actual | Severity | Root Cause | Fix Status |
|---|---------|-------------------|----------|--------|----------|------------|------------|
| F-001 | Sign In (Google) | Onboarding → SaveProgress → Tap "Google" | Google OAuth flow | Just advances to next step, no auth | CRITICAL | Stub implementation | Pending (escalated) |
| F-002 | Sign In (Email) | Onboarding → SaveProgress → Tap "Email" | Email auth flow | Just advances to next step, no auth | CRITICAL | Stub implementation | Pending (escalated) |
| F-003 | Username Check | Onboarding → UsernameEntry → Type any name | Check availability against DB | Always returns available (simulated) | CRITICAL | Task.sleep(500ms) + returns true | Pending (escalated) |
| F-004 | Delete Account | Settings → (expected) | Delete account option with confirmation | Feature does not exist | CRITICAL | Not implemented | Pending (escalated) |
| F-005 | Camera Denied | Deny camera permission → Try food scan | Guide to Settings / fallback UI | Silent failure, no recovery path | HIGH | No denied-state handling in CameraView | Pending |
| F-006 | Notification Permission | Entire app flow | Prompt for notifications at appropriate time | Never requested anywhere | HIGH | Not implemented | Pending |
| F-007 | Legal URLs | Paywall → Terms/Privacy links | Opens Qyra legal pages | Opens macra-app-star.github.io | HIGH | Hardcoded old URLs | Pending |
| F-008 | Subscription Sync | Purchase subscription → Backend sync | Reliable sync with retry | Fire-and-forget, can silently fail | HIGH | No retry mechanism | Pending |
| F-009 | SwiftData Migration | Schema change → App relaunch | Graceful migration | Deletes old store, user loses all data | HIGH | Fallback = destroy + recreate | Pending (escalated) |
| F-010 | Dev Skip Button | SignInView in non-DEBUG build | Not visible | May be visible depending on build config | MEDIUM | #if DEBUG may not cover all cases | Pending |
| F-011 | Paywall Fallback Prices | StoreKit fails to load → Paywall shown | Show error or retry | Shows static $9.99/$29.99 that may not match real prices | MEDIUM | Hardcoded fallback | Pending |
| F-012 | Profile Default Name | New user via Supabase trigger | Display name = user's name | Display name = "macra user" | MEDIUM | SQL migration default value | Pending |

---

*Last updated: 2026-03-31 — 12 functional defects identified*

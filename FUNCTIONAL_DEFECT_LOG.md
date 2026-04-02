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

| F-013 | Food Scan (Offline) | Scan food → CoreML classifies → no DB match | Show unreliable estimate warning | Logs meal with 0 calories silently | CRITICAL | No validation on zero-calorie results | **FIXED** — caps confidence at 30%, sets needsManualEntry |
| F-014 | Macro Precision | Log 10 meals across a day → check totals | Totals match sum of items | 3-5% undercount due to truncation | HIGH | Int truncation of Double values | **FIXED** — ViewModel uses Double, rounds at display |
| F-015 | AI Coach | Open AI coach → no disclaimer | Medical disclaimer shown | No disclaimer anywhere | CRITICAL | Not implemented | **FIXED** — added to chat header + detail view |
| F-016 | User Data Isolation | Sign out → Sign in as different user | See only new user's data | See ALL previous user's meals/goals | CRITICAL | Missing userId in fetch predicates | Pending (escalated) |
| F-017 | Gemini Prompt | Type malicious text in AI coach | Input sanitized | Raw user input in prompt template | HIGH | No input sanitization | Pending (escalated) |
| F-018 | API Key Exposure | Any Gemini API call | Key in auth header | Key in URL query parameter | MEDIUM | URL-based key passing | Pending |
| F-019 | Serving Size | Barcode scan → product missing servingSizeGrams | Warn about estimate | Assumes 100g serving (may be 30g) | HIGH | Default 100g fallback | Pending |
| F-020 | Timezone | Log meal at 11:59 PM on DST boundary | Correct date assignment | May assign to wrong day | MEDIUM | Calendar.startOfDay on DST transition | Pending |

---

*Last updated: 2026-04-01 — 20 functional defects identified, 3 fixed*
